defmodule Pulse.Application do
  @moduledoc """
  OTP application for Pulse.

  Starts the monitor dynamic supervisor and the `Pulse.Monitor` GenServer.
  Services are added or removed at runtime via `Pulse.Monitor` (e.g. from the TUI).
  """

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:pulse, :http_port, 4040)

    children = [
      Pulse.Monitor.Supervisor,
      Pulse.Monitor,
      {Bandit, plug: Pulse.Web, scheme: :http, port: port}
    ]

    opts = [strategy: :one_for_one, name: Pulse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
