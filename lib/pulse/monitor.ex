defmodule Pulse.Monitor do
  @moduledoc """
  Manages monitored services and their workers.

  Add or remove services at runtime; each service gets a `Pulse.Monitor.Worker`
  that performs GET requests and tracks latency.

  ## Example

      service = %Pulse.Service{id: :api, name: "API", url: "https://api.example.com/health"}
      :ok = Pulse.Monitor.add_service(service)
      Pulse.Monitor.list_services()
      #=> [%{service: service, pid: #PID<...>, latency_ms: nil}]
      Pulse.Monitor.check(:api)
      Pulse.Monitor.remove_service(:api)

  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_service(service) do
    GenServer.call(__MODULE__, {:add_service, service})
  end

  def remove_service(service_id) do
    GenServer.call(__MODULE__, {:remove_service, service_id})
  end

  def list_services do
    GenServer.call(__MODULE__, :list_services)
  end

  def check(service_id) do
    case get_pid(service_id) do
      nil -> :not_found
      pid -> Pulse.Monitor.Worker.check(pid); :ok
    end
  end

  defp get_pid(service_id) do
    GenServer.call(__MODULE__, {:get_pid, service_id})
  end

  @impl true
  def init(_opts), do: {:ok, %{workers: %{}}}

  @impl true
  def handle_call({:add_service, service}, _from, %{workers: workers} = state) do
    if Map.has_key?(workers, service.id) do
      {:reply, {:error, :already_exists}, state}
    else
      case start_worker(service) do
        {:ok, pid} ->
          {:reply, :ok, %{state | workers: Map.put(workers, service.id, {service, pid})}}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call({:remove_service, service_id}, _from, %{workers: workers} = state) do
    case Map.pop(workers, service_id) do
      {nil, _} ->
        {:reply, {:error, :not_found}, state}

      {{_service, pid}, new_workers} ->
        DynamicSupervisor.terminate_child(Pulse.Monitor.Supervisor, pid)
        {:reply, :ok, %{state | workers: new_workers}}
    end
  end

  @impl true
  def handle_call(:list_services, _from, %{workers: workers} = state) do
    entries =
      Enum.map(workers, fn {_id, {service, pid}} ->
        %{service: service, pid: pid, latency_ms: Pulse.Monitor.Worker.get_latency(pid)}
      end)

    {:reply, entries, state}
  end

  @impl true
  def handle_call({:get_pid, service_id}, _from, %{workers: workers} = state) do
    pid = workers |> Map.get(service_id) |> pid_from_entry()
    {:reply, pid, state}
  end

  defp pid_from_entry({_service, p}), do: p
  defp pid_from_entry(nil), do: nil

  defp start_worker(service) do
    spec = {Pulse.Monitor.Worker, [service: service, name: nil]}
    case DynamicSupervisor.start_child(Pulse.Monitor.Supervisor, spec) do
      {:ok, pid} -> {:ok, pid}
      {:ok, pid, _} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end
end
