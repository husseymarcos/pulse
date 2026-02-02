package tui

import (
	"fmt"

	"github.com/charmbracelet/lipgloss"
)

func render(m model) string {
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

	if m.adding {
		formTitle := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("12")).Render("Add service")
		help := helpStyle.Render("Enter: next / submit · Tab: next · Esc: cancel")
		return title + "\n" + formTitle + "\n\n  Name: " + m.nameInput.View() + "\n  URL:  " + m.urlInput.View() + "\n\n" + help
	}

	help := helpStyle.Render("a: add service · q: quit · ctrl+c: quit · ctrl+z: suspend")

	var body string
	if m.err != nil {
		body = lipgloss.NewStyle().Foreground(lipgloss.Color("9")).Render(m.err.Error()) + "\n\n"
	}
	if len(m.entries) == 0 && m.err == nil {
		body += "No services. Press a to add one.\n"
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
