package tui

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	tea "github.com/charmbracelet/bubbletea"
)

func fetchServices(apiURL string) tea.Cmd {
	return func() tea.Msg {
		resp, err := http.Get(apiURL + "/services")
		if err != nil {
			return servicesMsg{err: err}
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			return servicesMsg{err: fmt.Errorf("API returned %d", resp.StatusCode)}
		}

		var entries []serviceEntry
		if err := json.NewDecoder(resp.Body).Decode(&entries); err != nil {
			return servicesMsg{err: err}
		}
		return servicesMsg{entries: entries}
	}
}

func addService(apiURL, name, url string) tea.Cmd {
	return func() tea.Msg {
		body, _ := json.Marshal(map[string]string{"name": name, "url": url})
		resp, err := http.Post(apiURL+"/services", "application/json", bytes.NewReader(body))
		if err != nil {
			return addServiceDoneMsg{err: err}
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
			return addServiceDoneMsg{err: fmt.Errorf("API returned %d", resp.StatusCode)}
		}
		return addServiceDoneMsg{}
	}
}
