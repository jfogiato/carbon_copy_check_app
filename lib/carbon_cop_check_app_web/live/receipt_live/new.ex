defmodule CarbonCopCheckAppWeb.ReceiptLive.New do
  use CarbonCopCheckAppWeb, :live_view

  alias CarbonCopCheckApp.Receipts
  alias CarbonCopCheckApp.OCR
  alias CarbonCopCheckApp.Uploads

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Upload Receipt")
     |> assign(:uploaded_files, [])
     |> assign(:processing, false)
     |> allow_upload(:receipt_image,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt_image, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    socket = assign(socket, :processing, true)

    uploaded_files =
      consume_uploaded_entries(socket, :receipt_image, fn %{path: path}, entry ->
        # Save the file to our uploads directory
        case Uploads.save_receipt_image(path, entry.client_name) do
          {:ok, relative_path} -> {:ok, relative_path}
          {:error, reason} -> {:postpone, reason}
        end
      end)

    case uploaded_files do
      [image_path] ->
        # Get the full filesystem path for OCR
        full_path = Uploads.get_full_path(image_path)

        # Extract text via OCR
        {raw_text, parsed_items} =
          case OCR.extract_text(full_path) do
            {:ok, text} -> {text, OCR.parse_line_items(text)}
            {:error, _} -> {"", []}
          end

        # Create the receipt
        case Receipts.create_receipt(%{image_path: image_path, raw_ocr_text: raw_text}) do
          {:ok, receipt} ->
            # Create line items from parsed OCR
            Receipts.create_line_items_for_receipt(receipt, parsed_items)

            {:noreply,
             socket
             |> assign(:processing, false)
             |> put_flash(:info, "Receipt uploaded! Review and categorize the items.")
             |> push_navigate(to: ~p"/receipts/#{receipt.id}/edit")}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> assign(:processing, false)
             |> put_flash(:error, "Failed to save receipt")}
        end

      [] ->
        {:noreply,
         socket
         |> assign(:processing, false)
         |> put_flash(:error, "Please select an image to upload")}
    end
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "Invalid file type"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(err), do: "Error: #{inspect(err)}"
end
