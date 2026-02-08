package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"pulse/tui"
)

const (
	defaultAPIURL   = "http://localhost:4040"
	healthPath      = "/health"
	healthTimeout   = 30 * time.Second
	healthPollEvery = 300 * time.Millisecond
)

// releaseDir is set at build time for Homebrew (e.g. -ldflags "-X main.releaseDir=/path").
// When set, pulse starts the Elixir release from that path and then the TUI.
var releaseDir string

var version string // set by ldflags, e.g. -X main.version=0.1.0

func main() {
	standalone := flag.Bool("standalone", false, "start the Pulse API from this directory if not running (requires mix.exs)")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Parse()

	if *showVersion {
		if version == "" {
			version = "dev"
		}
		fmt.Println("pulse", version)
		os.Exit(0)
	}

	apiURL := os.Getenv("PULSE_API_URL")
	if apiURL == "" {
		apiURL = defaultAPIURL
	}

	useRelease := releaseDir != ""
	useMix := *standalone
	var backend *exec.Cmd
	if useRelease || useMix {
		var err error
		backend, err = ensureBackend(apiURL)
		if err != nil {
			log.Fatalf("pulse: %v", err)
		}
		if backend != nil {
			defer backend.Process.Kill()
		}
	}

	if logPath := os.Getenv("BUBBLETEA_LOG"); logPath != "" {
		f, err := tea.LogToFile(logPath, "pulse-tui")
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
	}

	clientID := tui.ReadClientID()
	p := tea.NewProgram(tui.New(apiURL, clientID))
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}


func ensureBackend(apiURL string) (*exec.Cmd, error) {
	if healthOK(apiURL) {
		return nil, nil
	}
	if releaseDir != "" {
		return startRelease(apiURL)
	}
	return startMix(apiURL)
}

func startRelease(apiURL string) (*exec.Cmd, error) {
	bin := filepath.Join(releaseDir, "bin", "pulse")
	if _, err := os.Stat(bin); err != nil {
		return nil, fmt.Errorf("release binary not found at %s: %w", bin, err)
	}
	cmd := exec.Command(bin, "start")
	cmd.Dir = releaseDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("starting release: %w", err)
	}
	if !waitForHealth(apiURL, healthTimeout) {
		cmd.Process.Kill()
		return nil, fmt.Errorf("API at %s did not become ready in %v", apiURL, healthTimeout)
	}
	return cmd, nil
}

func startMix(apiURL string) (*exec.Cmd, error) {
	cwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}
	if _, err := os.Stat(filepath.Join(cwd, "mix.exs")); err != nil {
		return nil, nil
	}
	cmd := exec.Command("mix", "run", "--no-halt")
	cmd.Dir = cwd
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	if !waitForHealth(apiURL, healthTimeout) {
		cmd.Process.Kill()
		return nil, fmt.Errorf("API at %s did not become ready in %v", apiURL, healthTimeout)
	}
	return cmd, nil
}

func healthOK(apiURL string) bool {
	resp, err := http.Get(apiURL + healthPath)
	if err != nil {
		return false
	}
	resp.Body.Close()
	return resp.StatusCode == http.StatusOK
}

func waitForHealth(apiURL string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if healthOK(apiURL) {
			return true
		}
		time.Sleep(healthPollEvery)
	}
	return false
}
