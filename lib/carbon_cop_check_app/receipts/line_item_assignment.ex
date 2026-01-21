defmodule CarbonCopCheckApp.Receipts.LineItemAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "line_item_assignments" do
    belongs_to :line_item, CarbonCopCheckApp.Receipts.LineItem
    belongs_to :person, CarbonCopCheckApp.Receipts.Person

    timestamps(type: :utc_datetime)
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:line_item_id, :person_id])
    |> validate_required([:line_item_id, :person_id])
    |> foreign_key_constraint(:line_item_id)
    |> foreign_key_constraint(:person_id)
    |> unique_constraint([:line_item_id, :person_id])
  end
end
