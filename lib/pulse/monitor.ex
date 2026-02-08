defmodule Pulse.Monitor do
  @moduledoc """
  Manages monitored services per client_id (no login).
  State is in-memory workers; persistence is in DB via Pulse.Storage.
  """

  use GenServer

  alias Pulse.Monitor.State, as: State
  alias Pulse.Storage

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_service(client_id, service) do
    GenServer.call(__MODULE__, {:add_service, client_id, service})
  end

  def remove_service(client_id, id) do
    GenServer.call(__MODULE__, {:remove_service, client_id, id})
  end

  def list_services(client_id) do
    GenServer.call(__MODULE__, {:list_services, client_id})
  end

  def check(client_id, id) do
    case get_pid(client_id, id) do
      nil -> :not_found
      pid ->
        Pulse.Monitor.Worker.check(pid)
        :ok
    end
  end

  defp get_pid(client_id, id) do
    GenServer.call(__MODULE__, {:get_pid, client_id, id})
  end

  @impl true
  def init(_opts), do: {:ok, %State{clients: %{}}}

  @impl true
  def handle_call({:add_service, client_id, service}, _from, state) do
    state = ensure_client_loaded(state, client_id)
    workers = Map.get(state.clients, client_id, %{})

    if url_taken?(workers, service.url) do
      {:reply, {:error, :already_exists}, state}
    else
        case Storage.insert_service(client_id, service.name, service.url) do
        {:ok, row} ->
          service_with_id = %{service | id: row.id}
          case start_worker(service_with_id) do
            {:ok, pid} ->
              new_workers = Map.put(workers, row.id, {service_with_id, pid})
              new_state = put_in(state.clients[client_id], new_workers)
              {:reply, {:ok, service_with_id}, new_state}
            {:error, reason} ->
              _ = Storage.delete_service(client_id, row.id)
              {:reply, {:error, reason}, state}
          end
        {:error, _} ->
          {:reply, {:error, :db_error}, state}
      end
    end
  end

  @impl true
  def handle_call({:remove_service, client_id, id}, _from, state) do
    state = ensure_client_loaded(state, client_id)
    workers = Map.get(state.clients, client_id, %{})

    case Map.pop(workers, id) do
      {nil, _} ->
        case Storage.delete_service(client_id, id) do
          {:ok, _} -> {:reply, :ok, state}
          _ -> {:reply, {:error, :not_found}, state}
        end

      {{_service, pid}, new_workers} ->
        _ = DynamicSupervisor.terminate_child(Pulse.Monitor.Supervisor, pid)
        _ = Storage.delete_service(client_id, id)
        new_state = put_in(state.clients[client_id], new_workers)
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:list_services, client_id}, _from, state) do
    state = ensure_client_loaded(state, client_id)
    workers = Map.get(state.clients, client_id, %{})

    services =
      Enum.map(workers, fn {_id, {service, pid}} ->
        %{service
          | latency_ms: Pulse.Monitor.Worker.get_latency(pid),
            status: Pulse.Monitor.Worker.get_status(pid)
        }
      end)

    {:reply, services, state}
  end

  @impl true
  def handle_call({:get_pid, client_id, id}, _from, state) do
    workers = Map.get(state.clients, client_id, %{})
    pid = workers |> Map.get(id) |> then(fn {_, p} -> p; nil -> nil end)
    {:reply, pid, state}
  end

  defp ensure_client_loaded(state, client_id) do
    if Map.has_key?(state.clients, client_id) do
      state
    else
      services = Storage.list_services(client_id)
      workers =
        Enum.reduce(services, %{}, fn service, acc ->
          case start_worker(service) do
            {:ok, pid} -> Map.put(acc, service.id, {service, pid})
            _ -> acc
          end
        end)
      put_in(state.clients[client_id], workers)
    end
  end

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
