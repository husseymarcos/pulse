defmodule Pulse.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :client_id, :string, null: false
      add :name, :string, null: false
      add :url, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:services, [:client_id])
  end
end
