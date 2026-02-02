package tui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/mattn/go-runewidth"
)

func repeatSpaces(n int) string { return strings.Repeat(" ", n) }

const (
	minTableWidth    = 50
	idColWidth       = 4
	statusColWidth   = 5
	latencyColWidth  = 9
	gapAfterId       = 1
	gapNameToStatus  = 0
	gapStatusToURL   = 3
	gapAfterURL      = 1
	fixedWidth       = idColWidth + gapAfterId + statusColWidth + latencyColWidth + gapNameToStatus + gapStatusToURL + gapAfterURL
)

// tableLayout computes column widths from terminal width.
func tableLayout(width int) (nameW, urlW int) {
	if width < minTableWidth {
		width = minTableWidth
	}
	remaining := width - fixedWidth
	if remaining < 10 {
		nameW, urlW = 4, 4
		return
	}
	nameW = remaining * 4 / 10
	if nameW < 4 {
		nameW = 4
	}
	urlW = remaining - nameW
	if urlW < 6 {
		urlW = 6
		nameW = remaining - urlW
	}
	return nameW, urlW
}

func render(m model) string {
	if m.quitting {
		return "Goodbye.\n"
	}

	title := styleTitle.Render("◆ " + m.title)
	status := styleStatus.Render("● " + m.status)
	help := styleHelp.Render

	if m.adding {
		formTitle := styleBold.Copy().Foreground(lipgloss.Color("12")).Render("Add service")
		return title + "\n" + formTitle + "\n\n  Name: " + m.nameInput.View() + "\n  URL:  " + m.urlInput.View() + "\n\n" + help("Enter: next / submit · Tab: next · Esc: cancel")
	}

	var body string
	if m.err != nil {
		body = styleError.Render(m.err.Error()) + "\n\n"
	} else if len(m.entries) == 0 {
		body = "No services. Press a to add one.\n"
	} else {
		body = renderServiceTable(m)
	}

	return title + "\n" + status + "\n\n" + body + "\n" + help("a: add service · q: quit · ctrl+c: quit · ctrl+z: suspend")
}

func renderServiceTable(m model) string {
	width := m.width
	if width <= 0 {
		width = 80
	}
	height := m.height
	if height <= 0 {
		height = 1000
	}

	nameW, urlW := tableLayout(width)

	headerName := runewidth.Truncate("Name", nameW, "…")
	headerURL := runewidth.Truncate("URL", urlW, "…")
	header := styleBold.Render(fmt.Sprintf("%-*s %-*s%-*s"+repeatSpaces(gapStatusToURL)+"%-*s %s",
		idColWidth, "#", nameW, headerName, statusColWidth, "Status", urlW, headerURL, "Latency"))
	out := header + "\n"

	maxRows := height - 8
	if maxRows < 1 {
		maxRows = 1
	}
	entries := m.entries
	more := 0
	if len(entries) > maxRows {
		entries = entries[:maxRows]
		more = len(m.entries) - maxRows
	}

	for _, e := range entries {
		lat := "—"
		if e.LatencyMs != nil {
			lat = fmt.Sprintf("%d ms", *e.LatencyMs)
		}
		statusLabel := "ERROR"
		if e.Status == "ok" {
			statusLabel = "OK"
		}
		statusLabel = runewidth.FillRight(statusLabel, statusColWidth)
		statusStr := styleError.Render(statusLabel)
		if e.Status == "ok" {
			statusStr = styleOK.Render(statusLabel)
		}
		name := runewidth.Truncate(e.Name, nameW, "…")
		url := runewidth.Truncate(e.URL, urlW, "…")
		out += fmt.Sprintf("%-*d %-*s%s"+repeatSpaces(gapStatusToURL)+"%-*s %s\n",
			idColWidth, e.ID, nameW, name, statusStr, urlW, url, lat)
	}
	if more > 0 {
		out += fmt.Sprintf("… %d more\n", more)
	}
	return out
}
