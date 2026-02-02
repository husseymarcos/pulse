defmodule Pulse.Service do
  @moduledoc """
  A monitored service: name and URL used for health checks.

  The `id` is set when the service is added via `Pulse.Monitor.add_service/1`
  (a random UUID). Omit `id` when creating a service.

  ## Example

      service = %Pulse.Service{name: "API", url: "https://api.example.com/health"}
      :ok = Pulse.Monitor.add_service(service)
      [entry] = Pulse.Monitor.list_services()
      entry.service.id
      #=> "550e8400-e29b-41d4-a716-446655440000"

  """

  use TypedStruct

  typedstruct do
    @typedoc "A monitored service. `id` is set when added via Pulse.Monitor.add_service/1 (UUID)."
    field :id, String.t() | nil, default: nil
    field :name, String.t(), enforce: true
    field :url, String.t(), enforce: true
  end
end
