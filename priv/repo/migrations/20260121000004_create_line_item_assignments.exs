defmodule CarbonCopCheckApp.Repo.Migrations.CreateLineItemAssignments do
  use Ecto.Migration

  def change do
    create table(:line_item_assignments) do
      add :line_item_id, references(:line_items, on_delete: :delete_all), null: false
      add :person_id, references(:people, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:line_item_assignments, [:line_item_id])
    create index(:line_item_assignments, [:person_id])
    create unique_index(:line_item_assignments, [:line_item_id, :person_id])
  end
end
