# Pulse

Service monitoring application that checks HTTP endpoints and tracks latency. Add or remove services at runtime via `Pulse.Monitor`; each service gets a worker that performs GET requests and records response time.

## Install with Homebrew

```bash
brew tap husseymarcos/pulse https://github.com/husseymarcos/pulse
brew install pulse 
pulse
```

The `pulse` command starts the API and opens the TUI.

## Requirements (for building from source)

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

### Single command (recommended to try)

From the project root, build and run the `pulse` binary with `-standalone`. It will start the Elixir API in the background (if not already running) and then launch the TUI. When you quit the TUI, the API is stopped.

```bash
go build -o pulse .
./pulse -standalone
```

Requires `mix` on your PATH and a compiled project (`mix deps.get && mix compile` once).

### Two terminals

**Terminal 1 — Elixir API**

```bash
iex -S mix
```

Starts `Pulse.Monitor` and the HTTP API on port 4040.

**Terminal 2 — TUI**

```bash
go run .
```

The TUI polls the API every 2 seconds and shows monitored services. Press **a** to add a service (name + URL), **q** or **ctrl+c** to quit.