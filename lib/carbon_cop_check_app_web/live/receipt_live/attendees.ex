defmodule CarbonCopCheckAppWeb.ReceiptLive.Attendees do
  use CarbonCopCheckAppWeb, :live_view

  alias CarbonCopCheckApp.Receipts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    receipt = Receipts.get_receipt!(id)
    people = Receipts.list_people()
    # Default: no people selected
    selected_ids = MapSet.new()

    {:ok,
     socket
     |> assign(:page_title, "Who's Here?")
     |> assign(:receipt, receipt)
     |> assign(:people, people)
     |> assign(:selected_ids, selected_ids)}
  end

  @impl true
  def handle_event("toggle_person", %{"person-id" => person_id}, socket) do
    person_id = String.to_integer(person_id)
    selected_ids = socket.assigns.selected_ids

    selected_ids =
      if MapSet.member?(selected_ids, person_id) do
        MapSet.delete(selected_ids, person_id)
      else
        MapSet.put(selected_ids, person_id)
      end

    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  @impl true
  def handle_event("select_all", _params, socket) do
    selected_ids = MapSet.new(Enum.map(socket.assigns.people, & &1.id))
    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  @impl true
  def handle_event("select_none", _params, socket) do
    {:noreply, assign(socket, :selected_ids, MapSet.new())}
  end

  @impl true
  def handle_event("continue", _params, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_ids)

    if selected_ids == [] do
      {:noreply, put_flash(socket, :error, "Select at least one person")}
    else
      Receipts.set_attendees(socket.assigns.receipt, selected_ids)

      {:noreply,
       socket
       |> push_navigate(to: ~p"/receipts/#{socket.assigns.receipt.id}/edit")}
    end
  end

  defp attendee_btn_class(selected?) do
    base = "p-4 rounded-xl border-3 border-cc-brown transition-all text-center"

    if selected? do
      "#{base} bg-cc-green text-white shadow-tattoo"
    else
      "#{base} bg-cc-cream text-cc-brown/50 hover:bg-cc-cream-dark"
    end
  end
end
