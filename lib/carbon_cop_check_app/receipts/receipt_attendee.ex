defmodule CarbonCopCheckApp.Receipts.ReceiptAttendee do
  use Ecto.Schema
  import Ecto.Changeset

  schema "receipt_attendees" do
    belongs_to :receipt, CarbonCopCheckApp.Receipts.Receipt
    belongs_to :person, CarbonCopCheckApp.Receipts.Person

    timestamps(type: :utc_datetime)
  end

  def changeset(attendee, attrs) do
    attendee
    |> cast(attrs, [:receipt_id, :person_id])
    |> validate_required([:receipt_id, :person_id])
    |> foreign_key_constraint(:receipt_id)
    |> foreign_key_constraint(:person_id)
    |> unique_constraint([:receipt_id, :person_id])
  end
end
