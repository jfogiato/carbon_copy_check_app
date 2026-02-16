defmodule CarbonCopCheckApp.OCR do
  @moduledoc """
  Handles OCR via Claude Vision API for extracting line items from receipt images.
  """

  require Logger

  @api_url "https://api.anthropic.com/v1/messages"

  @prompt """
  You are reading a receipt image from Carbon Copy brewery. Extract all individual line items (food, drinks, alcohol) with their prices.

  IMPORTANT categorization rules for Carbon Copy:
  - Carbon Copy house beers (categorize as "alcohol"): Bindle, Coy, Frill, Gully, Keen, Lane, Mote, Tender, Whir
  - Carbon Copy food items (categorize as "food"): pizza, rosso, pepperoni, sausage, samosa, mushroom, cheese, vegan, prosciutto, fig, wings, salad, caesar, cobb, fries, artichokes, zeppoles, chili, crisp
  - Beer/wine/spirits/cocktails → "alcohol"
  - Coffee, tea, soda, juice, water, non-alcoholic drinks → "drink"
  - Everything else → "food"

  DO NOT include subtotals, taxes, totals, tips, gratuity, service fees, or payment method lines.

  If an item has a quantity prefix (e.g., "2 Burger $24.00"), expand it into separate items with the price divided evenly (e.g., two "Burger" items at $12.00 each).

  Respond with ONLY valid JSON in this exact format (no markdown, no code fences):
  {
    "raw_text": "the full readable text of the receipt as you see it",
    "items": [
      {"name": "Item Name", "price": "12.50", "category": "food"},
      {"name": "Keen Pint", "price": "7.00", "category": "alcohol"}
    ]
  }

  If you cannot read the receipt or no items are found, return: {"raw_text": "", "items": []}
  """

  @doc """
  Extracts line items from a receipt image using Claude Vision API.
  Returns {:ok, raw_text, parsed_items} or {:error, reason}.
  Each item is %{name: string, price: Decimal, category: string}.
  """
  def extract_and_parse(image_path) do
    api_key = Application.get_env(:carbon_cop_check_app, :anthropic_api_key)

    if is_nil(api_key) or api_key == "" do
      {:error, "ANTHROPIC_API_KEY is not configured"}
    else
      with {:ok, image_data} <- read_and_encode_image(image_path),
           media_type <- media_type_for(image_path),
           {:ok, response} <- call_claude_api(api_key, image_data, media_type),
           {:ok, result} <- parse_response(response) do
        result
      end
    end
  end

  defp read_and_encode_image(path) do
    case File.read(path) do
      {:ok, data} -> {:ok, Base.encode64(data)}
      {:error, reason} -> {:error, "Failed to read image: #{inspect(reason)}"}
    end
  end

  defp media_type_for(path) do
    case Path.extname(path) |> String.downcase() do
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      _ -> "image/jpeg"
    end
  end

  defp call_claude_api(api_key, image_data, media_type) do
    body =
      Jason.encode!(%{
        model: "claude-haiku-4-5-20251001",
        max_tokens: 2048,
        messages: [
          %{
            role: "user",
            content: [
              %{
                type: "image",
                source: %{
                  type: "base64",
                  media_type: media_type,
                  data: image_data
                }
              },
              %{
                type: "text",
                text: @prompt
              }
            ]
          }
        ]
      })

    headers = [
      {"content-type", "application/json"},
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"}
    ]

    request = Finch.build(:post, @api_url, headers, body)

    case Finch.request(request, CarbonCopCheckApp.Finch, receive_timeout: 30_000) do
      {:ok, %Finch.Response{status: 200, body: resp_body}} ->
        {:ok, resp_body}

      {:ok, %Finch.Response{status: status, body: resp_body}} ->
        Logger.error("Claude API returned #{status}: #{resp_body}")
        {:error, "Claude API error (#{status})"}

      {:error, reason} ->
        Logger.error("Claude API request failed: #{inspect(reason)}")
        {:error, "Claude API request failed: #{inspect(reason)}"}
    end
  end

  defp parse_response(response_body) do
    with {:ok, resp} <- Jason.decode(response_body),
         %{"content" => [%{"text" => text} | _]} <- resp,
         clean_text = String.replace(text, ~r/```json\n?|```\n?/, ""),
         {:ok, parsed} <- Jason.decode(clean_text) do
      raw_text = Map.get(parsed, "raw_text", "")

      items =
        parsed
        |> Map.get("items", [])
        |> Enum.map(fn item ->
          {price, ""} = Decimal.parse(item["price"])
          %{name: item["name"], price: price, category: item["category"]}
        end)

      {:ok, {:ok, raw_text, items}}
    else
      error ->
        Logger.error("Failed to parse Claude response: #{inspect(error)}")
        {:error, "Failed to parse OCR response"}
    end
  end
end
