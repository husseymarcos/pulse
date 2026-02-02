package tui

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	tea "github.com/charmbracelet/bubbletea"
)

// serviceEntryRaw is used for decoding; latency_ms can come as int, float, or null from JSON.
type serviceEntryRaw struct {
	ID        int             `json:"id"`
	Name      string          `json:"name"`
	URL       string          `json:"url"`
	LatencyMs json.RawMessage `json:"latency_ms"`
	Status    string          `json:"status"`
}

func parseLatencyMs(raw json.RawMessage) *int {
	if len(raw) == 0 || string(raw) == "null" {
		return nil
	}
	var n int
	if err := json.Unmarshal(raw, &n); err == nil {
		return &n
	}
	var f float64
	if err := json.Unmarshal(raw, &f); err == nil {
		n := int(f)
		return &n
	}
	return nil
}

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

		var raw []serviceEntryRaw
		if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
			return servicesMsg{err: err}
		}
		entries := make([]serviceEntry, len(raw))
		for i, r := range raw {
			status := r.Status
			if status != "ok" {
				status = "error"
			}
			entries[i] = serviceEntry{
				ID:        r.ID,
				Name:      r.Name,
				URL:       r.URL,
				LatencyMs: parseLatencyMs(r.LatencyMs),
				Status:    status,
			}
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
