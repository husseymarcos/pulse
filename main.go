package main

import (
	"log"
	"os"
	tea "github.com/charmbracelet/bubbletea"
	"pulse/tui"
)

const defaultAPIURL = "http://localhost:4040"

func main() {
	apiURL := os.Getenv("PULSE_API_URL")
	if apiURL == "" {
		apiURL = defaultAPIURL
	}

	if logPath := os.Getenv("BUBBLETEA_LOG"); logPath != "" {
		f, err := tea.LogToFile(logPath, "pulse-tui")
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
	}

	p := tea.NewProgram(tui.New(apiURL))
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}
