// Pulse TUI — connects to the Elixir Pulse API and displays monitored services.
// Run: start Elixir app (iex -S mix), then: go run .
// Quit: q or ctrl+c

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

const defaultAPIURL = "http://localhost:4040"

type serviceEntry struct {
	ID        int   `json:"id"`
	Name      string `json:"name"`
	URL       string `json:"url"`
	LatencyMs *int   `json:"latency_ms"`
}

type model struct {
	apiURL   string
	title    string
	status   string
	entries  []serviceEntry
	err      error
	width    int
	height   int
	quitting bool
}

type servicesMsg struct {
	Entries []serviceEntry
	Err     error
}

type tickMsg struct{}

func main() {
	apiURL := os.Getenv("PULSE_API_URL")
	if apiURL == "" {
		apiURL = defaultAPIURL
	}

	logPath := os.Getenv("BUBBLETEA_LOG")
	if logPath != "" {
		f, err := tea.LogToFile(logPath, "pulse-tui")
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
	}

	p := tea.NewProgram(initialModel(apiURL))
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}

func initialModel(apiURL string) model {
	return model{
		apiURL:  apiURL,
		title:   "Pulse TUI",
		status:  "Connecting…",
		entries: nil,
	}
}

func (m model) Init() tea.Cmd {
	return fetchServices(m.apiURL)
}

func fetchServices(apiURL string) tea.Cmd {
	return func() tea.Msg {
		resp, err := http.Get(apiURL + "/services")
		if err != nil {
			return servicesMsg{Err: err}
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			return servicesMsg{Err: fmt.Errorf("API returned %d", resp.StatusCode)}
		}

		var entries []serviceEntry
		if err := json.NewDecoder(resp.Body).Decode(&entries); err != nil {
			return servicesMsg{Err: err}
		}
		return servicesMsg{Entries: entries}
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			m.quitting = true
			return m, tea.Quit
		case "ctrl+z":
			return m, tea.Suspend
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil
	case servicesMsg:
		m.entries = msg.Entries
		m.err = msg.Err
		if msg.Err != nil {
			m.status = "Error: " + msg.Err.Error()
		} else {
			m.status = fmt.Sprintf("%d service(s)", len(msg.Entries))
		}
		return m, tea.Tick(2*time.Second, func(time.Time) tea.Msg { return tickMsg{} })
	case tickMsg:
		return m, fetchServices(m.apiURL)
	}
	return m, nil
}

func (m model) View() string {
	if m.quitting {
		return "Goodbye.\n"
	}

	titleStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("12")).
		MarginBottom(1)

	statusStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("10")).
		MarginBottom(1)

	helpStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		MarginTop(2)

	title := titleStyle.Render("◆ " + m.title)
	status := statusStyle.Render("● " + m.status)
	help := helpStyle.Render("q: quit · ctrl+c: quit · ctrl+z: suspend")

	var body string
	if m.err != nil {
		body = lipgloss.NewStyle().Foreground(lipgloss.Color("9")).Render(m.err.Error()) + "\n\n"
	}
	if len(m.entries) == 0 && m.err == nil {
		body += "No services. Add services from the Elixir app (Pulse.Monitor.add_service/1).\n"
	} else {
		header := lipgloss.NewStyle().Bold(true).Render("ID   Name              URL                              Latency")
		body += header + "\n"
		for _, e := range m.entries {
			lat := "—"
			if e.LatencyMs != nil {
				lat = fmt.Sprintf("%d ms", *e.LatencyMs)
			}
			body += fmt.Sprintf("%-4d %-17s %-32s %s\n", e.ID, truncate(e.Name, 16), truncate(e.URL, 31), lat)
		}
	}

	return title + "\n" + status + "\n\n" + body + "\n" + help
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max-1] + "…"
}
