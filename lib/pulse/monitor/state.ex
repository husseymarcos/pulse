defmodule Pulse.Monitor.State do
  @moduledoc false
  use TypedStruct

  @type entry_value :: {Pulse.Service.t(), pid()}

  typedstruct do
    field :workers, %{optional(integer()) => entry_value()}, default: %{}
    field :next_id, integer(), default: 1
  end
end
