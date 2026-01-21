defmodule CarbonCopCheckApp.Calculator do
  @moduledoc """
  Calculates the split amounts for each person on a receipt.

  Business rules:
  - Food: 3% kitchen fee (pre-tax) + 8% tax on (subtotal + fee)
  - Drink: 8% tax (no kitchen fee)
  - Alcohol: 10% tax (no kitchen fee)
  - Tip: Proportional to pre-tax subtotal
  """

  alias CarbonCopCheckApp.Receipts.Receipt

  @kitchen_fee_rate Decimal.new("0.03")
  @food_tax_rate Decimal.new("0.08")
  @drink_tax_rate Decimal.new("0.08")
  @alcohol_tax_rate Decimal.new("0.10")

  @doc """
  Calculates the split for each person assigned to items on the receipt.

  Returns a map of person_id => %{
    subtotal: Decimal,
    kitchen_fee: Decimal,
    tax: Decimal,
    tip_share: Decimal,
    total: Decimal,
    items: [%{name, price, category, split_count}]
  }
  """
  def calculate_splits(%Receipt{} = receipt) do
    line_items = receipt.line_items
    tip_amount = receipt.tip_amount || Decimal.new(0)

    # Build a map of person_id => list of their items with share amounts
    person_items = build_person_items(line_items)

    # Calculate totals for each person
    person_totals =
      Enum.map(person_items, fn {person_id, items} ->
        {person_id, calculate_person_totals(items)}
      end)
      |> Map.new()

    # Calculate the overall pre-tax subtotal for tip proportioning
    overall_subtotal =
      person_totals
      |> Enum.map(fn {_person_id, totals} -> totals.subtotal end)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    # Add tip share to each person's totals
    Enum.map(person_totals, fn {person_id, totals} ->
      tip_share = calculate_tip_share(totals.subtotal, overall_subtotal, tip_amount)

      total =
        totals.subtotal
        |> Decimal.add(totals.kitchen_fee)
        |> Decimal.add(totals.tax)
        |> Decimal.add(tip_share)

      {person_id, Map.merge(totals, %{tip_share: tip_share, total: total})}
    end)
    |> Map.new()
  end

  defp build_person_items(line_items) do
    Enum.reduce(line_items, %{}, fn line_item, acc ->
      assignments = line_item.line_item_assignments || []
      split_count = max(length(assignments), 1)

      share_price =
        line_item.price
        |> Decimal.div(split_count)
        |> Decimal.round(2)

      item_info = %{
        name: line_item.name,
        price: share_price,
        original_price: line_item.price,
        category: line_item.category,
        split_count: split_count
      }

      Enum.reduce(assignments, acc, fn assignment, inner_acc ->
        person_id = assignment.person_id
        existing_items = Map.get(inner_acc, person_id, [])
        Map.put(inner_acc, person_id, [item_info | existing_items])
      end)
    end)
  end

  defp calculate_person_totals(items) do
    # Group items by category
    {food_items, drink_items, alcohol_items} = categorize_items(items)

    # Calculate food subtotal with kitchen fee
    food_subtotal = sum_prices(food_items)
    kitchen_fee = Decimal.mult(food_subtotal, @kitchen_fee_rate) |> Decimal.round(2)
    food_taxable = Decimal.add(food_subtotal, kitchen_fee)
    food_tax = Decimal.mult(food_taxable, @food_tax_rate) |> Decimal.round(2)

    # Calculate drink subtotal and tax
    drink_subtotal = sum_prices(drink_items)
    drink_tax = Decimal.mult(drink_subtotal, @drink_tax_rate) |> Decimal.round(2)

    # Calculate alcohol subtotal and tax
    alcohol_subtotal = sum_prices(alcohol_items)
    alcohol_tax = Decimal.mult(alcohol_subtotal, @alcohol_tax_rate) |> Decimal.round(2)

    # Total subtotal (pre-tax, pre-fee)
    subtotal =
      food_subtotal
      |> Decimal.add(drink_subtotal)
      |> Decimal.add(alcohol_subtotal)

    # Total tax
    total_tax =
      food_tax
      |> Decimal.add(drink_tax)
      |> Decimal.add(alcohol_tax)

    %{
      subtotal: subtotal,
      kitchen_fee: kitchen_fee,
      tax: total_tax,
      items: Enum.reverse(items),
      food_subtotal: food_subtotal,
      drink_subtotal: drink_subtotal,
      alcohol_subtotal: alcohol_subtotal
    }
  end

  defp categorize_items(items) do
    Enum.reduce(items, {[], [], []}, fn item, {food, drink, alcohol} ->
      case item.category do
        "food" -> {[item | food], drink, alcohol}
        "drink" -> {food, [item | drink], alcohol}
        "alcohol" -> {food, drink, [item | alcohol]}
        _ -> {[item | food], drink, alcohol}
      end
    end)
  end

  defp sum_prices(items) do
    items
    |> Enum.map(& &1.price)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_tip_share(person_subtotal, overall_subtotal, tip_amount) do
    if Decimal.compare(overall_subtotal, Decimal.new(0)) == :gt do
      person_subtotal
      |> Decimal.div(overall_subtotal)
      |> Decimal.mult(tip_amount)
      |> Decimal.round(2)
    else
      Decimal.new(0)
    end
  end

  @doc """
  Calculates the grand total for the receipt (all persons combined).
  """
  def calculate_grand_total(%Receipt{} = receipt) do
    splits = calculate_splits(receipt)

    splits
    |> Enum.map(fn {_person_id, totals} -> totals.total end)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end
end
