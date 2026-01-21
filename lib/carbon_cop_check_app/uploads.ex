defmodule CarbonCopCheckApp.Uploads do
  @moduledoc """
  Handles file uploads for receipt images.
  """

  @doc """
  Returns the uploads directory path.
  In production (releases), uses /app/uploads for persistent volume storage.
  In development, uses priv/static/uploads.
  """
  def uploads_dir do
    if Application.get_env(:carbon_cop_check_app, :env) == :prod do
      "/app/uploads"
    else
      "priv/static/uploads"
    end
  end

  @doc """
  Saves an uploaded receipt image to the uploads directory.
  Returns {:ok, relative_path} or {:error, reason}.
  """
  def save_receipt_image(source_path, original_filename) do
    ensure_uploads_dir()

    # Generate a unique filename
    extension = Path.extname(original_filename)
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random_suffix = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
    filename = "receipt_#{timestamp}_#{random_suffix}#{extension}"

    dest_path = Path.join(uploads_dir(), filename)

    case File.cp(source_path, dest_path) do
      :ok ->
        # Return path relative to web root for serving
        {:ok, "/uploads/#{filename}"}

      {:error, reason} ->
        {:error, "Failed to save image: #{inspect(reason)}"}
    end
  end

  @doc """
  Converts a web-relative path to a full filesystem path.
  """
  def get_full_path(relative_path) do
    # Remove leading slash
    filename = String.trim_leading(relative_path, "/uploads/")
    Path.join(uploads_dir(), filename)
  end

  @doc """
  Deletes an uploaded file.
  """
  def delete_file(relative_path) do
    full_path = get_full_path(relative_path)
    File.rm(full_path)
  end

  defp ensure_uploads_dir do
    File.mkdir_p!(uploads_dir())
  end
end
