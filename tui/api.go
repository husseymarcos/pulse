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

func rawToEntry(r serviceEntryRaw) serviceEntry {
	status := "error"
	if r.Status == "ok" {
		status = "ok"
	}
	return serviceEntry{
		ID:        r.ID,
		Name:      r.Name,
		URL:       r.URL,
		LatencyMs: parseLatencyMs(r.LatencyMs),
		Status:    status,
	}
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

func fetchServices(apiURL, clientID string) tea.Cmd {
	return func() tea.Msg {
		req, _ := http.NewRequest(http.MethodGet, apiURL+"/services", nil)
		if clientID != "" {
			req.Header.Set("X-Client-ID", clientID)
		}
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			return servicesMsg{err: err}
		}
		defer resp.Body.Close()

		respClientID := resp.Header.Get("X-Client-ID")
		if resp.StatusCode != http.StatusOK {
			return servicesMsg{err: fmt.Errorf("API returned %d", resp.StatusCode), clientID: respClientID}
		}

		var raw []serviceEntryRaw
		if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
			return servicesMsg{err: err, clientID: respClientID}
		}
		entries := make([]serviceEntry, len(raw))
		for i := range raw {
			entries[i] = rawToEntry(raw[i])
		}
		return servicesMsg{entries: entries, clientID: respClientID}
	}
}

func addService(apiURL, clientID, name, url string) tea.Cmd {
	return func() tea.Msg {
		body, _ := json.Marshal(map[string]string{"name": name, "url": url})
		req, _ := http.NewRequest(http.MethodPost, apiURL+"/services", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		if clientID != "" {
			req.Header.Set("X-Client-ID", clientID)
		}
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			return addServiceDoneMsg{err: err}
		}
		defer resp.Body.Close()
		respClientID := resp.Header.Get("X-Client-ID")
		if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
			return addServiceDoneMsg{err: fmt.Errorf("API returned %d", resp.StatusCode), clientID: respClientID}
		}
		return addServiceDoneMsg{clientID: respClientID}
	}
}
