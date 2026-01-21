defmodule CarbonCopCheckAppWeb.ReceiptLive.Index do
  use CarbonCopCheckAppWeb, :live_view

  alias CarbonCopCheckApp.Receipts
  alias CarbonCopCheckApp.Calculator

  @impl true
  def mount(_params, _session, socket) do
    receipts = Receipts.list_receipts()

    {:ok,
     socket
     |> assign(:receipt_count, length(receipts))
     |> stream(:receipts, receipts)}
  end

  def calculate_total(receipt) do
    Calculator.calculate_grand_total(receipt)
  end

  def format_money(decimal) when is_struct(decimal, Decimal) do
    decimal |> Decimal.round(2) |> Decimal.to_string()
  end

  def format_money(_), do: "0.00"

  def to_eastern(datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("America/New_York")
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Receipts")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    receipt = Receipts.get_receipt!(id)
    {:ok, _} = Receipts.delete_receipt(receipt)

    {:noreply,
     socket
     |> update(:receipt_count, &(&1 - 1))
     |> stream_delete(:receipts, receipt)}
  end
end
