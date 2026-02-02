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
		errorStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("9"))
		okStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("10"))
		header := lipgloss.NewStyle().Bold(true).Render("ID   Name              Status   URL                         Latency")
		body += header + "\n"
		for _, e := range m.entries {
			lat := "—"
			if e.LatencyMs != nil {
				lat = fmt.Sprintf("%d ms", *e.LatencyMs)
			}
			statusStr := errorStyle.Render("ERROR")
			if e.Status == "ok" {
				statusStr = okStyle.Render("OK")
			}
			body += fmt.Sprintf("%-4d %-16s %s %-28s %s\n", e.ID, truncate(e.Name, 16), statusStr, truncate(e.URL, 28), lat)
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
