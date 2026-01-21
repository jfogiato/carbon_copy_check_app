defmodule CarbonCopCheckApp.Receipts do
  @moduledoc """
  The Receipts context handles all operations related to receipts,
  line items, people, and their assignments.
  """

  import Ecto.Query, warn: false
  alias CarbonCopCheckApp.Repo

  alias CarbonCopCheckApp.Receipts.{Person, Receipt, LineItem, LineItemAssignment}

  # People

  def list_people do
    Repo.all(from p in Person, order_by: p.name)
  end

  def get_person!(id), do: Repo.get!(Person, id)

  def create_person(attrs \\ %{}) do
    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert()
  end

  def update_person(%Person{} = person, attrs) do
    person
    |> Person.changeset(attrs)
    |> Repo.update()
  end

  def delete_person(%Person{} = person) do
    Repo.delete(person)
  end

  def change_person(%Person{} = person, attrs \\ %{}) do
    Person.changeset(person, attrs)
  end

  # Receipts

  def list_receipts do
    Receipt
    |> order_by(desc: :inserted_at)
    |> preload(line_items: :people)
    |> Repo.all()
  end

  def get_receipt!(id) do
    Receipt
    |> preload(line_items: [:people, :line_item_assignments])
    |> Repo.get!(id)
  end

  def create_receipt(attrs \\ %{}) do
    %Receipt{}
    |> Receipt.changeset(attrs)
    |> Repo.insert()
  end

  def update_receipt(%Receipt{} = receipt, attrs) do
    receipt
    |> Receipt.changeset(attrs)
    |> Repo.update()
  end

  def delete_receipt(%Receipt{} = receipt) do
    Repo.delete(receipt)
  end

  def change_receipt(%Receipt{} = receipt, attrs \\ %{}) do
    Receipt.changeset(receipt, attrs)
  end

  # Line Items

  def get_line_item!(id) do
    LineItem
    |> preload([:people, :line_item_assignments])
    |> Repo.get!(id)
  end

  def create_line_item(attrs \\ %{}) do
    %LineItem{}
    |> LineItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_line_item(%LineItem{} = line_item, attrs) do
    line_item
    |> LineItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_line_item(%LineItem{} = line_item) do
    Repo.delete(line_item)
  end

  def change_line_item(%LineItem{} = line_item, attrs \\ %{}) do
    LineItem.changeset(line_item, attrs)
  end

  # Line Item Assignments

  def toggle_person_assignment(%LineItem{} = line_item, %Person{} = person) do
    case get_assignment(line_item.id, person.id) do
      nil ->
        create_assignment(line_item.id, person.id)

      assignment ->
        Repo.delete(assignment)
    end
  end

  defp get_assignment(line_item_id, person_id) do
    Repo.get_by(LineItemAssignment, line_item_id: line_item_id, person_id: person_id)
  end

  defp create_assignment(line_item_id, person_id) do
    %LineItemAssignment{}
    |> LineItemAssignment.changeset(%{line_item_id: line_item_id, person_id: person_id})
    |> Repo.insert()
  end

  def person_assigned?(%LineItem{} = line_item, person_id) do
    Enum.any?(line_item.line_item_assignments, &(&1.person_id == person_id))
  end

  # Bulk operations for creating line items from OCR

  def create_line_items_for_receipt(%Receipt{} = receipt, items) when is_list(items) do
    Enum.map(items, fn item_attrs ->
      attrs = Map.put(item_attrs, :receipt_id, receipt.id)
      create_line_item(attrs)
    end)
  end
end
