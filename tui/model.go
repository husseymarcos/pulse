package tui

import (
	"fmt"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type serviceEntry struct {
	ID        int    `json:"id"`
	Name      string `json:"name"`
	URL       string `json:"url"`
	LatencyMs *int   `json:"latency_ms"`
	Status    string `json:"status"`
}

type model struct {
	apiURL    string
	clientID  string
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
	entries  []serviceEntry
	err      error
	clientID string // from X-Client-ID response header; persist if set
}

type tickMsg struct{}

type addServiceDoneMsg struct {
	err      error
	clientID string
}

// New returns a tea.Model for the Pulse TUI. clientID is the anonymous client ID (persisted locally, no login).
func New(apiURL, clientID string) tea.Model {
	return newModel(apiURL, clientID)
}

func newModel(apiURL, clientID string) model {
	inputStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("12"))
	textStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("15"))
	newInput := func(placeholder string) textinput.Model {
		ti := textinput.New()
		ti.Placeholder = placeholder
		ti.Width = 40
		ti.PromptStyle = inputStyle
		ti.TextStyle = textStyle
		return ti
	}

	return model{
		apiURL:    apiURL,
		clientID:  clientID,
		title:     "Pulse TUI",
		status:    "Connecting…",
		entries:   nil,
		adding:    false,
		nameInput: newInput("e.g. API"),
		urlInput:  newInput("https://example.com/health"),
		focus:     0,
	}
}

func (m model) Init() tea.Cmd {
	return fetchServices(m.apiURL, m.clientID)
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
			return m.resetForm(), nil
		case "enter":
			if m.focus == 0 {
				return m.focusURL(), textinput.Blink
			}
			name, url := m.nameInput.Value(), m.urlInput.Value()
			m = m.resetForm()
			if name == "" || url == "" {
				m.status = "Name and URL required"
				return m, nil
			}
			return m, addService(m.apiURL, m.clientID, name, url)
		case "tab":
			if m.focus == 0 {
				return m.focusURL(), textinput.Blink
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

func (m model) resetForm() model {
	m.adding = false
	m.nameInput.Reset()
	m.urlInput.Reset()
	m.nameInput.Blur()
	m.urlInput.Blur()
	m.focus = 0
	return m
}

func (m model) focusURL() model {
	m.focus = 1
	m.nameInput.Blur()
	m.urlInput.Focus()
	return m
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
			m.focus = 0
			m.nameInput.Focus()
			m.urlInput.Blur()
			return m, textinput.Blink
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil
	case servicesMsg:
		if msg.clientID != "" {
			_ = WriteClientID(msg.clientID)
			m.clientID = msg.clientID
		}
		m.entries = msg.entries
		m.err = msg.err
		if msg.err != nil {
			m.status = "Error: " + msg.err.Error()
		} else {
			m.status = fmt.Sprintf("%d service(s)", len(msg.entries))
		}
		interval := 2 * time.Second
		if msg.err != nil {
			interval = 5 * time.Second
		}
		return m, tea.Tick(interval, func(time.Time) tea.Msg { return tickMsg{} })
	case addServiceDoneMsg:
		if msg.clientID != "" {
			_ = WriteClientID(msg.clientID)
			m.clientID = msg.clientID
		}
		if msg.err != nil {
			m.status = "Add failed: " + msg.err.Error()
		} else {
			m.status = "Service added. Refreshing…"
		}
		return m, fetchServices(m.apiURL, m.clientID)
	case tickMsg:
		return m, fetchServices(m.apiURL, m.clientID)
	}
	return m, nil
}
