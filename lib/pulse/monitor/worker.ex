defmodule Pulse.Monitor.Worker do
  @moduledoc """
  GenServer that monitors a single service: performs GET requests and tracks latency.

  Started by `Pulse.Monitor` for each added service. Use `check/1` to trigger a GET
  and `get_latency/1` to read the last measured latency (in milliseconds).
  """

  use GenServer

  require Mint.HTTP

  def start_link(opts) do
    service = Keyword.fetch!(opts, :service)
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, service, name: name)
  end

  def check(pid \\ __MODULE__) do
    GenServer.cast(pid, :check)
  end

  def get_latency(pid \\ __MODULE__) do
    GenServer.call(pid, :get_latency)
  end

  @impl true
  def init(service) do
    state = %{
      service: service,
      conn: nil,
      request_ref: nil,
      start_time: nil,
      latency_ms: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_cast(:check, %{service: service} = state) do
    case Pulse.Monitor.HTTP.connect_get(service.url) do
      {:ok, conn, request_ref, start_time} ->
        {:noreply, %{state | conn: conn, request_ref: request_ref, start_time: start_time}}

      {:error, _} ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_latency, _from, %{latency_ms: latency_ms} = state) do
    {:reply, latency_ms, state}
  end

  @impl true
  def handle_info(
        message,
        %{conn: conn, request_ref: request_ref, start_time: start_time} = state
      )
      when not is_nil(conn) and Mint.HTTP.is_connection_message(conn, message) do
    case Mint.HTTP.stream(conn, message) do
      {:ok, conn, responses} ->
        state = %{state | conn: conn}
        state = Pulse.Monitor.Response.apply(state, responses, request_ref, start_time)
        {:noreply, state}

      {:error, conn, _reason, _responses} ->
        _ = Mint.HTTP.close(conn)
        {:noreply, %{state | conn: nil, request_ref: nil, start_time: nil}}
    end
  end

  def handle_info(_message, state), do: {:noreply, state}
end
