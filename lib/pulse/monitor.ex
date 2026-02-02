defmodule Pulse.Monitor do
  @moduledoc """
  Manages monitored services and their workers.

  Add or remove services at runtime; each service gets a `Pulse.Monitor.Worker`
  that performs GET requests and tracks latency.

  ## Example

      service = %Pulse.Service{name: "API", url: "https://api.example.com/health"}
      :ok = Pulse.Monitor.add_service(service)
      [entry] = Pulse.Monitor.list_services()
      Pulse.Monitor.check(entry.service.id)
      Pulse.Monitor.remove_service(entry.service.id)

  """

  use GenServer

  alias Pulse.Monitor.State, as: State
  alias Pulse.Monitor.Entry, as: Entry

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_service(service) do
    GenServer.call(__MODULE__, {:add_service, service})
  end

  def remove_service(id) do
    GenServer.call(__MODULE__, {:remove_service, id})
  end

  def list_services do
    GenServer.call(__MODULE__, :list_services)
  end

  def check(id) do
    case get_pid(id) do
      nil ->
        :not_found

      pid ->
        Pulse.Monitor.Worker.check(pid)
        :ok
    end
  end

  defp get_pid(id) do
    GenServer.call(__MODULE__, {:get_pid, id})
  end

  @impl true
  def init(_opts), do: {:ok, %State{workers: %{}, next_id: 1}}

  @impl true
  def handle_call({:add_service, service}, _from, %State{workers: workers, next_id: id} = state) do
    if url_taken?(workers, service.url) do
      {:reply, {:error, :already_exists}, state}
    else
      service_with_id = %{service | id: id}
      case start_worker(service_with_id) do
        {:ok, pid} ->
          new_state = %{
            state
            | workers: Map.put(workers, id, {service_with_id, pid}),
              next_id: id + 1
          }
          {:reply, :ok, new_state}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call({:remove_service, id}, _from, %State{workers: workers} = state) do
    case Map.pop(workers, id) do
      {nil, _} ->
        {:reply, {:error, :not_found}, state}

      {{_service, pid}, new_workers} ->
        DynamicSupervisor.terminate_child(Pulse.Monitor.Supervisor, pid)
        {:reply, :ok, %{state | workers: new_workers}}
    end
  end

  @impl true
  def handle_call(:list_services, _from, %State{workers: workers} = state) do
    entries =
      Enum.map(workers, fn {_id, {service, pid}} ->
        %Entry{
          service: service,
          pid: pid,
          latency_ms: Pulse.Monitor.Worker.get_latency(pid),
          status: Pulse.Monitor.Worker.get_status(pid)
        }
      end)

    {:reply, entries, state}
  end

  @impl true
  def handle_call({:get_pid, id}, _from, %State{workers: workers} = state) do
    pid = workers |> Map.get(id) |> pid_from_entry()
    {:reply, pid, state}
  end

  defp pid_from_entry({_service, p}), do: p
  defp pid_from_entry(nil), do: nil

  defp url_taken?(workers, url) do
    Enum.any?(workers, fn {_id, {service, _pid}} -> service.url == url end)
  end

  defp start_worker(service) do
    spec = {Pulse.Monitor.Worker, [service: service, name: nil]}

    case DynamicSupervisor.start_child(Pulse.Monitor.Supervisor, spec) do
      {:ok, pid} -> {:ok, pid}
      {:ok, pid, _} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end
end
