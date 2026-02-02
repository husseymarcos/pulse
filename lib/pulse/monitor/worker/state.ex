defmodule Pulse.Monitor.Worker.State do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :service, Pulse.Service.t()
    field :conn, Mint.HTTP.t() | nil, default: nil
    field :request_ref, reference() | nil, default: nil
    field :start_time, integer() | nil, default: nil
    field :latency_ms, integer() | nil, default: nil
  end
end
