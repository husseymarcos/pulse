defmodule Pulse.Monitor.Response do
  @moduledoc """
  Processes Mint response stream: detects `:done`, computes latency, logs, and closes the connection.
  """

  require Logger
  require Mint.HTTP

  def apply(state, responses, request_ref, start_time) do
    if done?(responses, request_ref) do
      latency_ms = System.monotonic_time(:millisecond) - start_time

      Logger.info(
        "Pulse.Monitor.Worker #{state.service.name}: GET #{state.service.url} took #{latency_ms}ms"
      )

      _ = Mint.HTTP.close(state.conn)

      %{
        state
        | conn: nil,
          request_ref: nil,
          start_time: nil,
          latency_ms: latency_ms
      }
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
end
