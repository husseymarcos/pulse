defmodule Pulse.Storage do
  @moduledoc "Persistence for services by client_id (no login)."
  import Ecto.Query
  alias Pulse.Repo
  alias Pulse.Storage.Service, as: ServiceSchema
  alias Pulse.Service

  def list_services(client_id) do
    from(s in ServiceSchema, where: s.client_id == ^client_id, order_by: [asc: s.id])
    |> Repo.all()
    |> Enum.map(&row_to_service/1)
  end

  def insert_service(client_id, name, url) do
    %ServiceSchema{}
    |> ServiceSchema.changeset(%{client_id: client_id, name: name, url: url})
    |> Repo.insert()
  end

  def delete_service(client_id, id) do
    case Repo.get_by(ServiceSchema, id: id, client_id: client_id) do
      nil -> {:error, :not_found}
      row -> Repo.delete(row)
    end
  end

  defp row_to_service(row) do
    %Service{
      id: row.id,
      name: row.name,
      url: row.url,
      latency_ms: nil,
      status: "ok"
    }
  end
end
