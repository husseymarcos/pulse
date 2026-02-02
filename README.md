# Pulse

Service monitoring application that checks HTTP endpoints and tracks latency. Add or remove services at runtime via `Pulse.Monitor`; each service gets a worker that performs GET requests and records response time.

## Requirements

- Elixir ~> 1.19
- OTP 25+

## Setup

```bash
git clone https://github.com/husseymarcos/pulse.git
cd pulse
mix deps.get
mix compile
```

## Usage

Start the application (e.g. `iex -S mix`). The app starts `Pulse.Monitor`; add services and trigger checks:
