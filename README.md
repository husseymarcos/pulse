# Pulse — Service monitoring with TUI

Monitors HTTP endpoints and tracks latency. Add or remove services from the TUI or via the API; each service has a worker that runs GET checks and records response time.

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

## Deploying the server (no login)

The API can run separately from the TUI. Services are stored in PostgreSQL and scoped by an anonymous **client ID** (no login): the TUI persists a UUID in `~/.config/pulse/client_id` and sends it in the `X-Client-ID` header. The server returns that header when it generates a new ID so the client can save it.

### Database

1. Create a Postgres database and set `DATABASE_URL`:
   ```bash
   export DATABASE_URL="ecto://USER:PASSWORD@HOST/DATABASE"
   ```
2. Run migrations:
   ```bash
   MIX_ENV=prod mix ecto.migrate
   ```
3. For local dev (default DB `pulse_dev`):
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

### Run the server

- **Dev:** `iex -S mix` or `mix run --no-halt` (API on port 4040; override with config `:pulse, :http_port`).
- **Prod:** build a release (`MIX_ENV=prod mix release`) and start it; ensure `DATABASE_URL` is set in the environment.

### Use the TUI against a remote server

Set the API URL and run the TUI (do not use `-standalone` so it does not start a local server):

```bash
export PULSE_API_URL="https://your-pulse-server.example.com"
pulse
```

The TUI will send `X-Client-ID` from `~/.config/pulse/client_id`; if missing, the server assigns one and returns it in the response, and the TUI saves it for next time.