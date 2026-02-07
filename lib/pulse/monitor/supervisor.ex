defmodule Pulse.Monitor.Supervisor do
  @moduledoc "DynamicSupervisor for Pulse.Monitor.Worker (one per service)."
  use DynamicSupervisor

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)
end
