# Pulse

Service monitoring application that checks HTTP endpoints and tracks latency. Add or remove services at runtime via `Pulse.Monitor`; each service gets a worker that performs GET requests and records response time.

## Requirements

- Elixir ~> 1.19
- OTP 25+
- Go 1.21+ (for the TUI)

## Setup

```bash
git clone https://github.com/husseymarcos/pulse.git
cd pulse
mix deps.get
mix compile
```

For the TUI:

```bash
go mod tidy
```

## Start both (Elixir app and TUI)

**Terminal 1 — Elixir API**

```bash
iex -S mix
```

Starts `Pulse.Monitor` and the HTTP API on port 4040.

**Terminal 2 — TUI**

```bash
go run .
```

The TUI polls the API every 2 seconds and shows monitored services. Press `q` or `ctrl+c` to quit.

## HTTP API

- **GET /health** — health check (`{"status":"ok"}`).
- **GET /services** — JSON list of monitored services (id, name, url, latency_ms).

Add services from IEx, e.g.:

```elixir
Pulse.Monitor.add_service(%Pulse.Service{name: "Example", url: "https://example.com"})
Pulse.Monitor.check(1)
```
