package tui

import (
	"fmt"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type serviceEntry struct {
	ID        int   `json:"id"`
	Name      string `json:"name"`
	URL       string `json:"url"`
	LatencyMs *int   `json:"latency_ms"`
}

type model struct {
	apiURL    string
	title     string
	status    string
	entries   []serviceEntry
	err       error
	width     int
	height    int
	quitting  bool
	adding    bool
	nameInput textinput.Model
	urlInput  textinput.Model
	focus     int
}

type servicesMsg struct {
	entries []serviceEntry
	err     error
}

type tickMsg struct{}

type addServiceDoneMsg struct {
	err error
}

// New returns a tea.Model for the Pulse TUI.
func New(apiURL string) tea.Model {
	return newModel(apiURL)
}

func newModel(apiURL string) model {
	ti := textinput.New()
	ti.Placeholder = "e.g. API"
	ti.Width = 40
	ti.PromptStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("12"))
	ti.TextStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("15"))

	urlTi := textinput.New()
	urlTi.Placeholder = "https://example.com/health"
	urlTi.Width = 40
	urlTi.PromptStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("12"))
	urlTi.TextStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("15"))

	return model{
		apiURL:    apiURL,
		title:     "Pulse TUI",
		status:    "Connecting…",
		entries:   nil,
		adding:    false,
		nameInput: ti,
		urlInput:  urlTi,
		focus:     0,
	}
}

func (m model) Init() tea.Cmd {
	return fetchServices(m.apiURL)
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	if m.adding {
		return m.updateForm(msg)
	}
	return m.updateList(msg)
}

func (m model) View() string {
	return render(m)
}

func (m model) updateForm(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "esc":
			m.adding = false
			m.nameInput.Reset()
			m.urlInput.Reset()
			m.nameInput.Blur()
			m.urlInput.Blur()
			m.focus = 0
			return m, nil
		case "enter":
			if m.focus == 0 {
				m.focus = 1
				m.nameInput.Blur()
				m.urlInput.Focus()
				return m, textinput.Blink
			}
			name := m.nameInput.Value()
			url := m.urlInput.Value()
			m.adding = false
			m.nameInput.Reset()
			m.urlInput.Reset()
			m.nameInput.Blur()
			m.urlInput.Blur()
			m.focus = 0
			if name == "" || url == "" {
				m.status = "Name and URL required"
				return m, nil
			}
			return m, addService(m.apiURL, name, url)
		case "tab":
			if m.focus == 0 {
				m.focus = 1
				m.nameInput.Blur()
				m.urlInput.Focus()
				return m, textinput.Blink
			}
			return m, nil
		}
		if m.focus == 0 {
			var cmd tea.Cmd
			m.nameInput, cmd = m.nameInput.Update(msg)
			return m, cmd
		}
		var cmd tea.Cmd
		m.urlInput, cmd = m.urlInput.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m model) updateList(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			m.quitting = true
			return m, tea.Quit
		case "ctrl+z":
			return m, tea.Suspend
		case "a":
			m.adding = true
			m.nameInput.Focus()
			m.urlInput.Blur()
			m.focus = 0
			return m, textinput.Blink
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil
	case servicesMsg:
		m.entries = msg.entries
		m.err = msg.err
		if msg.err != nil {
			m.status = "Error: " + msg.err.Error()
		} else {
			m.status = fmt.Sprintf("%d service(s)", len(msg.entries))
		}
		return m, tea.Tick(2*time.Second, func(time.Time) tea.Msg { return tickMsg{} })
	case addServiceDoneMsg:
		if msg.err != nil {
			m.status = "Add failed: " + msg.err.Error()
		} else {
			m.status = "Service added. Refreshing…"
		}
		return m, fetchServices(m.apiURL)
	case tickMsg:
		return m, fetchServices(m.apiURL)
	}
	return m, nil
}
