package tui

import "github.com/charmbracelet/lipgloss"

var (
	styleTitle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("12")).
			MarginBottom(1)

	styleStatus = lipgloss.NewStyle().
			Foreground(lipgloss.Color("10")).
			MarginBottom(1)

	styleHelp = lipgloss.NewStyle().
			Foreground(lipgloss.Color("241")).
			MarginTop(2)

	styleError = lipgloss.NewStyle().Foreground(lipgloss.Color("9"))
	styleOK    = lipgloss.NewStyle().Foreground(lipgloss.Color("10"))
	styleBold  = lipgloss.NewStyle().Bold(true)
)
