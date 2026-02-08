defmodule Pulse.Storage.Service do
  @moduledoc "Ecto schema for persisted services. Scoped by client_id (no login)."
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "services" do
    field :client_id, :string
    field :name, :string
    field :url, :string
    timestamps(type: :utc_datetime)
  end

  def changeset(service, attrs) do
    service
    |> cast(attrs, [:client_id, :name, :url])
    |> validate_required([:client_id, :name, :url])
    |> validate_length(:name, min: 1)
    |> validate_length(:url, min: 1)
  end
end
