defmodule Pulse.Repo do
  @moduledoc "Ecto repo for Pulse. Configure via config :pulse, Pulse.Repo."
  use Ecto.Repo, otp_app: :pulse, adapter: Ecto.Adapters.Postgres
end
