defmodule CarbonCopCheckAppWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use CarbonCopCheckAppWeb, :html

  embed_templates "page_html/*"

  def calculate_total(receipt) do
    subtotal =
      Enum.reduce(receipt.line_items, Decimal.new("0"), fn item, acc ->
        Decimal.add(acc, item.price)
      end)

    tip = receipt.tip_amount || Decimal.new("0")
    Decimal.add(subtotal, tip) |> format_money()
  end

  defp format_money(decimal) do
    decimal
    |> Decimal.round(2)
    |> Decimal.to_string()
  end
end
