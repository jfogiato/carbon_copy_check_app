defmodule CarbonCopCheckApp.Repo.Migrations.CreateLineItems do
  use Ecto.Migration

  def change do
    create table(:line_items) do
      add :name, :string, null: false
      add :price, :decimal, precision: 10, scale: 2, null: false
      add :category, :string, null: false, default: "food"
      add :receipt_id, references(:receipts, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:line_items, [:receipt_id])
  end
end
