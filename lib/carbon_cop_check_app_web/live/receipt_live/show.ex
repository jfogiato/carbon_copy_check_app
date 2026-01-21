defmodule CarbonCopCheckAppWeb.ReceiptLive.Show do
  use CarbonCopCheckAppWeb, :live_view

  alias CarbonCopCheckApp.Receipts
  alias CarbonCopCheckApp.Calculator

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    receipt = Receipts.get_receipt!(id)
    people = Receipts.list_people()
    splits = Calculator.calculate_splits(receipt)

    {:ok,
     socket
     |> assign(:page_title, "Receipt Summary")
     |> assign(:receipt, receipt)
     |> assign(:people, people)
     |> assign(:splits, splits)}
  end

  def format_money(decimal) when is_struct(decimal, Decimal) do
    decimal
    |> Decimal.round(2)
    |> Decimal.to_string()
  end

  def format_money(_), do: "0.00"

  def category_pill_class("food"), do: "pill-food text-xs ml-1"
  def category_pill_class("drink"), do: "pill-drink text-xs ml-1"
  def category_pill_class("alcohol"), do: "pill-alcohol text-xs ml-1"
  def category_pill_class(_), do: "bg-cc-cream text-cc-brown text-xs px-2 py-0.5 rounded-full ml-1"
end
