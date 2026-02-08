defmodule Pulse.Monitor.State do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :clients, %{optional(String.t()) => %{optional(integer()) => {Pulse.Service.t(), pid()}}}, default: %{}
  end
end
