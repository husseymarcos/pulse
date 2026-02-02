defmodule Pulse.Monitor.Response do
  @moduledoc """
  Processes Mint response stream: detects `:done`, computes latency, logs, and closes the connection.
  """

  require Logger
  require Mint.HTTP

  @spec apply(
          Pulse.Monitor.Worker.State.t(),
          [Mint.Types.response()],
          reference(),
          integer()
        ) :: Pulse.Monitor.Worker.State.t()
  def apply(state, responses, request_ref, start_time) do
    if done?(responses, request_ref) and is_integer(start_time) do
      status_code = status_code(responses, request_ref)
      latency_ms = System.monotonic_time(:millisecond) - start_time
      last_status = if status_code in 200..299, do: :ok, else: :error

      Logger.info(
        "Pulse.Monitor.Worker #{state.service.name}: GET #{state.service.url} #{status_code} #{latency_ms}ms"
      )

      _ = Mint.HTTP.close(state.conn)

      state
      |> Map.put(:conn, nil)
      |> Map.put(:request_ref, nil)
      |> Map.put(:start_time, nil)
      |> Map.put(:latency_ms, if(last_status == :ok, do: latency_ms, else: state.latency_ms))
      |> Map.put(:last_status, last_status)
    else
      state
    end
  end

  defp done?(responses, request_ref) do
    Enum.any?(responses, fn
      {:done, ^request_ref} -> true
      _ -> false
    end)
  end

  defp status_code(responses, request_ref) do
    Enum.find_value(responses, 0, fn
      {:status, ^request_ref, code} -> code
      _ -> nil
    end) || 0
  end
end
