defmodule CarbonCopCheckAppWeb.PeopleLive.FormComponent do
  use CarbonCopCheckAppWeb, :live_component

  alias CarbonCopCheckApp.Receipts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="font-script text-4xl text-cc-brown mb-6"><%= @title %></h2>

      <.simple_form
        for={@form}
        id="person-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <div>
            <label class="block font-display text-sm text-cc-brown mb-2">NAME</label>
            <input
              type="text"
              name={@form[:name].name}
              value={@form[:name].value}
              class="input-tattoo"
              placeholder="Enter name..."
              autofocus
            />
            <.error :for={msg <- @form[:name].errors}>
              <%= translate_error(msg) %>
            </.error>
          </div>
        </div>

        <div class="mt-8 flex gap-4">
          <button type="submit" class="btn-tattoo-success flex-1" phx-disable-with="Saving...">
            Save Friend
          </button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{person: person} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Receipts.change_person(person))
     end)}
  end

  @impl true
  def handle_event("validate", %{"person" => person_params}, socket) do
    changeset = Receipts.change_person(socket.assigns.person, person_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    save_person(socket, socket.assigns.action, person_params)
  end

  defp save_person(socket, :edit, person_params) do
    case Receipts.update_person(socket.assigns.person, person_params) do
      {:ok, person} ->
        notify_parent({:saved, person})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_person(socket, :new, person_params) do
    case Receipts.create_person(person_params) do
      {:ok, person} ->
        notify_parent({:saved, person})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
