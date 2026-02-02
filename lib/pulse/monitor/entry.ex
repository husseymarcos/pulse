defmodule Pulse.Monitor.Entry do
  @moduledoc """
  A monitored service entry: service, worker pid, and last latency (if any).
  """
  use TypedStruct

  typedstruct do
    field :service, Pulse.Service.t()
    field :pid, pid()
    field :latency_ms, integer() | nil, default: nil
  end
end
