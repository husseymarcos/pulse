defmodule Pulse.Monitor.Response do
  @moduledoc "Processes Mint stream: on :done computes latency, logs, closes conn, updates state."
  require Logger
  require Mint.HTTP

  def apply(state, responses, request_ref, start_time) do
    if done?(responses, request_ref) and is_integer(start_time) do
      code = (Enum.find_value(responses, fn {:status, ^request_ref, c} -> c; _ -> nil end) || 0)
      latency_ms = System.monotonic_time(:millisecond) - start_time
      status = if code in 200..299, do: "ok", else: "error"
      Logger.info("Worker #{state.service.name}: GET #{state.service.url} #{code} #{latency_ms}ms")
      _ = Mint.HTTP.close(state.conn)
      service = %{state.service | status: status, latency_ms: (if status == "ok", do: latency_ms, else: state.service.latency_ms)}
      %{state | service: service, conn: nil, request_ref: nil, start_time: nil}
    else
      state
    end
  end

  defp done?(responses, ref), do: Enum.any?(responses, fn {:done, ^ref} -> true; _ -> false end)
end
