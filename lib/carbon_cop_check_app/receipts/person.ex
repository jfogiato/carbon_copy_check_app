defmodule CarbonCopCheckApp.Receipts.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string

    has_many :line_item_assignments, CarbonCopCheckApp.Receipts.LineItemAssignment
    has_many :line_items, through: [:line_item_assignments, :line_item]

    timestamps(type: :utc_datetime)
  end

  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
