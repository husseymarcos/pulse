defmodule Pulse.Monitor.State do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :workers, %{optional(integer()) => {Pulse.Service.t(), pid()}}, default: %{}
    field :next_id, integer(), default: 1
  end
end
