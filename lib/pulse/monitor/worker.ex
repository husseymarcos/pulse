defmodule Pulse.Monitor.Worker do
  @moduledoc "GenServer per service: GET health checks, tracks latency. Started by Pulse.Monitor."

  use GenServer
  require Mint.HTTP

  @type state :: %{
          service: Pulse.Service.t(),
          conn: Mint.HTTP.t() | nil,
          request_ref: reference() | nil,
          start_time: integer() | nil
        }

  def start_link(opts) do
    service = Keyword.fetch!(opts, :service)
    GenServer.start_link(__MODULE__, service, name: Keyword.get(opts, :name, __MODULE__))
  end

  def check(pid \\ __MODULE__), do: GenServer.cast(pid, :check)
  def get_latency(pid \\ __MODULE__), do: GenServer.call(pid, :get_latency)
  def get_status(pid \\ __MODULE__), do: GenServer.call(pid, :get_status)

  @impl true
  def init(service) do
    Process.send_after(self(), :run_check, 500)
    {:ok, %{service: service, conn: nil, request_ref: nil, start_time: nil}}
  end

  @impl true
  def handle_cast(:check, state), do: {:noreply, maybe_start_check(state)}

  @impl true
  def handle_call(:get_latency, _from, state), do: {:reply, state.service.latency_ms, state}
  def handle_call(:get_status, _from, state), do: {:reply, state.service.status, state}

  @impl true
  @spec handle_info(term(), state()) :: {:noreply, state()}
  def handle_info(msg, state) when not is_nil(state.conn) and Mint.HTTP.is_connection_message(state.conn, msg) do
    case Mint.HTTP.stream(state.conn, msg) do
      {:ok, conn, responses} ->
        state = Pulse.Monitor.Response.apply(%{state | conn: conn}, responses, state.request_ref, state.start_time)
        {:noreply, state}
      {:error, conn, _reason, _} ->
        _ = Mint.HTTP.close(conn)
        {:noreply, %{state | conn: nil, request_ref: nil, start_time: nil, service: %{state.service | status: "error"}}}
    end
  end

  def handle_info(:run_check, state), do: {:noreply, maybe_start_check(state)}
  def handle_info(_, state), do: {:noreply, state}

  defp maybe_start_check(%{conn: nil, service: service} = state) do
    case Pulse.Monitor.HTTP.connect_get(service.url) do
      {:ok, conn, request_ref, start_time} -> %{state | conn: conn, request_ref: request_ref, start_time: start_time}
      {:error, _} -> state
    end
  end
  defp maybe_start_check(state), do: state
end
