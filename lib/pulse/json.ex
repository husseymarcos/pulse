defmodule Pulse.JSON do
  @moduledoc """
  JSON encoding implementations for Pulse structs.

  Handles custom encoding logic, such as converting atoms to strings
  for JSON serialization.
  """
end

defimpl Jason.Encoder, for: Pulse.Service do
  def encode(%Pulse.Service{} = service, opts) do
    service
    |> Map.from_struct()
    |> Map.update!(:status, fn status -> if(status == :ok, do: "ok", else: "error") end)
    |> Jason.Encode.map(opts)
  end
end
