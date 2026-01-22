defmodule CarbonCopCheckApp.OCR do
  @moduledoc """
  Handles OCR (Optical Character Recognition) via Tesseract
  for extracting text from receipt images.
  """

  # Lines containing these terms should be filtered out (case-insensitive)
  @excluded_terms ~w(
    subtotal sub-total sub_total
    total grand_total grandtotal
    tax sales_tax salestax liquor_tax liquortax
    service_fee servicefee gratuity tip
    change cash credit card visa mastercard amex
    thank you thanks
    balance due amount_due
  )

  # Carbon Copy house beers - these unique names need explicit matching
  @cc_beers ~w(
    bindle coy frill gully keen lane mote tender whir
  )

  # Carbon Copy food items for better matching
  @cc_food_items ~w(
    pizza rosso pepperoni sausage samosa mushroom cheese vegan prosciutto fig
    wings salad caesar cobb fries artichokes zeppoles chili crisp
  )

  @doc """
  Checks if Tesseract is installed and available.
  """
  def tesseract_available? do
    case System.cmd("which", ["tesseract"], stderr_to_stdout: true) do
      {path, 0} when byte_size(path) > 0 -> true
      _ -> false
    end
  end

  @doc """
  Extracts text from an image file using Tesseract OCR.
  Returns {:ok, text} or {:error, reason}.
  """
  def extract_text(image_path) do
    if tesseract_available?() do
      case System.cmd("tesseract", [image_path, "stdout"], stderr_to_stdout: true) do
        {output, 0} -> {:ok, output}
        {error, _} -> {:error, "Tesseract error: #{error}"}
      end
    else
      {:error, "Tesseract is not installed. Run: brew install tesseract"}
    end
  end

  @doc """
  Parses OCR text output and attempts to extract line items.
  Returns a list of %{name: string, price: Decimal, category: string}.

  Features:
  - Filters out subtotals, taxes, totals, etc.
  - Expands quantity prefixes (e.g., "2 Burger" becomes two separate items)

  This is a best-effort parser - receipt formats vary widely,
  so users should review and edit the extracted items.
  """
  def parse_line_items(text) when is_binary(text) do
    text
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Enum.filter(&(&1 != nil))
    |> Enum.filter(&(not excluded_item?(&1)))
    |> Enum.flat_map(&expand_quantity/1)
  end

  def parse_line_items(_), do: []

  defp parse_line(line) do
    line = String.trim(line)

    # Try different patterns for price extraction
    cond do
      # Pattern: "Item Name $12.34" or "Item Name 12.34"
      match = Regex.run(~r/^(.+?)\s+\$?(\d+\.\d{2})\s*$/, line) ->
        [_, name, price] = match
        build_item(name, price)

      # Pattern: "$12.34 Item Name"
      match = Regex.run(~r/^\$?(\d+\.\d{2})\s+(.+)$/, line) ->
        [_, price, name] = match
        build_item(name, price)

      # Pattern: "Item Name... $12.34" (with dots/dashes as separator)
      match = Regex.run(~r/^(.+?)[.\-\s]{2,}\$?(\d+\.\d{2})\s*$/, line) ->
        [_, name, price] = match
        build_item(name, price)

      true ->
        nil
    end
  end

  defp build_item(name, price_str) do
    name = String.trim(name)

    case Decimal.parse(price_str) do
      {price, ""} when name != "" ->
        %{name: name, price: price, category: guess_category(name)}

      _ ->
        nil
    end
  end

  # Check if the item name matches any excluded terms
  defp excluded_item?(%{name: name}) do
    normalized = name |> String.downcase() |> String.replace(~r/[\s_-]+/, "")

    Enum.any?(@excluded_terms, fn term ->
      clean_term = String.replace(term, "_", "")
      String.contains?(normalized, clean_term)
    end)
  end

  # Expand items with quantity prefixes into multiple items
  # e.g., "2 Traminette Glass" at $18.00 -> two items at $9.00 each
  # Also strips leading "1" from items like "1 Bindle" -> "Bindle"
  defp expand_quantity(%{name: name, price: price, category: category} = item) do
    # Match patterns like "2 Item Name" or "2x Item Name" or "2 x Item Name"
    case Regex.run(~r/^(\d+)\s*x?\s+(.+)$/i, name) do
      [_, qty_str, item_name] ->
        qty = String.to_integer(qty_str)
        clean_name = String.trim(item_name)

        cond do
          qty == 1 ->
            # Just strip the "1" prefix, keep same price
            [%{name: clean_name, price: price, category: category}]

          qty > 1 and qty <= 10 ->
            # Divide price evenly among the items
            unit_price = Decimal.div(price, qty) |> Decimal.round(2)

            # Create qty number of items
            for _ <- 1..qty do
              %{name: clean_name, price: unit_price, category: category}
            end

          true ->
            # qty is 0 or > 10, likely not a real quantity prefix
            [item]
        end

      nil ->
        [item]
    end
  end

  # Make a guess at the category based on common keywords
  defp guess_category(name) do
    lower_name = String.downcase(name)
    # Extract individual words for exact matching (for CC beer names)
    words = String.split(lower_name, ~r/[\s\-_]+/)

    cond do
      # Carbon Copy house beers (exact word match since names like "Coy" are short)
      Enum.any?(@cc_beers, fn beer -> beer in words end) ->
        "alcohol"

      # Carbon Copy food items
      Enum.any?(@cc_food_items, fn food -> String.contains?(lower_name, food) end) ->
        "food"

      # Generic alcohol indicators
      String.contains?(lower_name, ~w(beer ale ipa lager stout pilsner porter witbier
        wine glass bottle whiskey bourbon vodka gin rum tequila cocktail martini
        margarita sangria mimosa bellini spritz draft pint cider mead seltzer hard
        4 pack 4-pack 4pack can cans)) ->
        "alcohol"

      # Non-alcoholic drink indicators
      String.contains?(lower_name, ~w(coffee espresso latte cappuccino mocha tea
        soda pop coke pepsi sprite juice water lemonade smoothie shake malt
        arnold palmer)) ->
        "drink"

      # Default to food
      true ->
        "food"
    end
  end
end
