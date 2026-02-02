defmodule Pulse.Service do
  @moduledoc """
  A monitored service: id, name, and URL used for health checks.

  ## Example

      service = %Pulse.Service{
        id: :api,
        name: "API",
        url: "https://api.example.com/health"
      }

      service.url
      #=> "https://api.example.com/health"

  """

  defstruct [:id, :name, :url]

  @type t :: %__MODULE__{
          id: term(),
          name: String.t(),
          url: String.t()
        }
end
