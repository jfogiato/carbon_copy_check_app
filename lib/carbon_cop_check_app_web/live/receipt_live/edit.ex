defmodule CarbonCopCheckAppWeb.ReceiptLive.Edit do
  use CarbonCopCheckAppWeb, :live_view

  alias CarbonCopCheckApp.Receipts
  alias CarbonCopCheckApp.Receipts.LineItem
  alias CarbonCopCheckApp.Calculator

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    receipt = Receipts.get_receipt!(id)
    people = Receipts.list_people()
    splits = Calculator.calculate_splits(receipt)

    {:ok,
     socket
     |> assign(:page_title, "Edit Receipt")
     |> assign(:receipt, receipt)
     |> assign(:people, people)
     |> assign(:splits, splits)
     |> assign(:editing_item, nil)
     |> assign(:new_item_form, to_form(Receipts.change_line_item(%LineItem{}), as: "line_item"))}
  end

  @impl true
  def handle_event("update_category", %{"item_id" => item_id, "category" => category}, socket) do
    line_item = Receipts.get_line_item!(item_id)
    {:ok, _} = Receipts.update_line_item(line_item, %{category: category})

    {:noreply, reload_receipt(socket)}
  end

  @impl true
  def handle_event("toggle_person", %{"item_id" => item_id, "person_id" => person_id}, socket) do
    line_item = Receipts.get_line_item!(item_id)
    person = Receipts.get_person!(person_id)
    Receipts.toggle_person_assignment(line_item, person)

    {:noreply, reload_receipt(socket)}
  end

  @impl true
  def handle_event("update_tip", %{"value" => tip_str}, socket) do
    tip_amount =
      case Decimal.parse(tip_str) do
        {decimal, ""} -> decimal
        {decimal, _} -> decimal
        _ -> Decimal.new(0)
      end

    {:ok, _} = Receipts.update_receipt(socket.assigns.receipt, %{tip_amount: tip_amount})

    {:noreply, reload_receipt(socket)}
  end

  @impl true
  def handle_event("delete_item", %{"item_id" => item_id}, socket) do
    line_item = Receipts.get_line_item!(item_id)
    {:ok, _} = Receipts.delete_line_item(line_item)

    {:noreply, reload_receipt(socket)}
  end

  @impl true
  def handle_event("edit_item", %{"item_id" => item_id}, socket) do
    line_item = Receipts.get_line_item!(item_id)
    {:noreply, assign(socket, :editing_item, line_item)}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing_item, nil)}
  end

  @impl true
  def handle_event("save_item", %{"name" => name, "price" => price_str}, socket) do
    price =
      case Decimal.parse(price_str) do
        {decimal, ""} -> decimal
        _ -> Decimal.new(0)
      end

    {:ok, _} = Receipts.update_line_item(socket.assigns.editing_item, %{name: name, price: price})

    socket =
      socket
      |> assign(:editing_item, nil)
      |> reload_receipt()

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_new_item", %{"line_item" => item_params}, socket) do
    changeset =
      %LineItem{}
      |> Receipts.change_line_item(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :new_item_form, to_form(changeset))}
  end

  @impl true
  def handle_event("add_item", %{"line_item" => item_params}, socket) do
    attrs =
      item_params
      |> Map.put("receipt_id", socket.assigns.receipt.id)
      |> Map.put("category", "food")

    case Receipts.create_line_item(attrs) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:new_item_form, to_form(Receipts.change_line_item(%LineItem{}), as: "line_item"))
         |> reload_receipt()}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_item_form, to_form(changeset))}
    end
  end

  defp reload_receipt(socket) do
    receipt = Receipts.get_receipt!(socket.assigns.receipt.id)
    splits = Calculator.calculate_splits(receipt)

    socket
    |> assign(:receipt, receipt)
    |> assign(:splits, splits)
  end

  def category_btn_class(current, target) do
    base = "px-3 py-1.5 text-sm font-display rounded-lg border-2 border-cc-brown transition-all"

    if current == target do
      case target do
        "food" -> "#{base} bg-cc-green text-white shadow-tattoo-sm"
        "drink" -> "#{base} bg-cc-blue text-white shadow-tattoo-sm"
        "alcohol" -> "#{base} bg-cc-orange text-white shadow-tattoo-sm"
      end
    else
      "#{base} bg-cc-cream text-cc-brown hover:bg-cc-cream-dark"
    end
  end

  def person_btn_class(assigned?) do
    base = "person-toggle"

    if assigned? do
      "#{base} person-toggle-active"
    else
      "#{base} person-toggle-inactive"
    end
  end

  def format_money(decimal) when is_struct(decimal, Decimal) do
    decimal
    |> Decimal.round(2)
    |> Decimal.to_string()
  end

  def format_money(_), do: "0.00"
end
