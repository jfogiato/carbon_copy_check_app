defmodule CarbonCopCheckApp.Receipts.Receipt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "receipts" do
    field :image_path, :string
    field :tip_amount, :decimal, default: Decimal.new(0)
    field :raw_ocr_text, :string

    has_many :line_items, CarbonCopCheckApp.Receipts.LineItem

    timestamps(type: :utc_datetime)
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [:image_path, :tip_amount, :raw_ocr_text])
    |> validate_number(:tip_amount, greater_than_or_equal_to: 0)
  end
end
