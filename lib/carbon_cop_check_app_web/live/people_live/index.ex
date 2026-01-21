defmodule CarbonCopCheckAppWeb.PeopleLive.Index do
  use CarbonCopCheckAppWeb, :live_view

  alias CarbonCopCheckApp.Receipts
  alias CarbonCopCheckApp.Receipts.Person

  @impl true
  def mount(_params, _session, socket) do
    people = Receipts.list_people()

    {:ok,
     socket
     |> assign(:people_count, length(people))
     |> stream(:people, people)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Person")
    |> assign(:person, Receipts.get_person!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Person")
    |> assign(:person, %Person{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Trivia Friends")
    |> assign(:person, nil)
  end

  @impl true
  def handle_info({CarbonCopCheckAppWeb.PeopleLive.FormComponent, {:saved, person}}, socket) do
    # Only increment count for new people (not edits)
    socket =
      if socket.assigns.live_action == :new do
        update(socket, :people_count, &(&1 + 1))
      else
        socket
      end

    {:noreply, stream_insert(socket, :people, person)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    person = Receipts.get_person!(id)
    {:ok, _} = Receipts.delete_person(person)

    {:noreply,
     socket
     |> update(:people_count, &(&1 - 1))
     |> stream_delete(:people, person)}
  end
end
