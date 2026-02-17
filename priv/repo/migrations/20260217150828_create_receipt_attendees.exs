defmodule CarbonCopCheckApp.Repo.Migrations.CreateReceiptAttendees do
  use Ecto.Migration

  def change do
    create table(:receipt_attendees) do
      add :receipt_id, references(:receipts, on_delete: :delete_all), null: false
      add :person_id, references(:people, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:receipt_attendees, [:receipt_id, :person_id])
    create index(:receipt_attendees, [:receipt_id])
  end
end
