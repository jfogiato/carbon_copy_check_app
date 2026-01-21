defmodule CarbonCopCheckApp.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:people, [:name])
  end
end
