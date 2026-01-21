defmodule CarbonCopCheckApp.Repo.Migrations.CreateReceipts do
  use Ecto.Migration

  def change do
    create table(:receipts) do
      add :image_path, :string
      add :tip_amount, :decimal, precision: 10, scale: 2, default: 0
      add :raw_ocr_text, :text

      timestamps(type: :utc_datetime)
    end
  end
end
