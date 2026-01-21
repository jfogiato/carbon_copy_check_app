defmodule CarbonCopCheckApp.Receipts.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(food drink alcohol)

  schema "line_items" do
    field :name, :string
    field :price, :decimal
    field :category, :string, default: "food"

    belongs_to :receipt, CarbonCopCheckApp.Receipts.Receipt
    has_many :line_item_assignments, CarbonCopCheckApp.Receipts.LineItemAssignment
    has_many :people, through: [:line_item_assignments, :person]

    timestamps(type: :utc_datetime)
  end

  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:name, :price, :category, :receipt_id])
    |> validate_required([:name, :price, :receipt_id])
    |> validate_inclusion(:category, @categories)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:receipt_id)
  end

  def categories, do: @categories
end
