package tui

import (
	"os"
	"path/filepath"
	"strings"
)

func clientIDPath() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	pulseDir := filepath.Join(dir, "pulse")
	if err := os.MkdirAll(pulseDir, 0700); err != nil {
		return "", err
	}
	return filepath.Join(pulseDir, "client_id"), nil
}

func ReadClientID() string {
	path, err := clientIDPath()
	if err != nil {
		return ""
	}
	b, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(b))
}

func WriteClientID(id string) error {
	id = strings.TrimSpace(id)
	if id == "" {
		return nil
	}
	path, err := clientIDPath()
	if err != nil {
		return err
	}
	return os.WriteFile(path, []byte(id), 0600)
}
