defmodule Pulse.Application do
  @moduledoc "Starts Monitor.Supervisor, Monitor, and Bandit (Pulse.Web)."
  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:pulse, :http_port, 4040)
    children = [
      Pulse.Repo,
      Pulse.Monitor.Supervisor,
      Pulse.Monitor,
      {Bandit, plug: Pulse.Web, scheme: :http, port: port}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Pulse.Supervisor)
  end
end
