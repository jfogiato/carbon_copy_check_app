# Carbon Copy Check App

A receipt-splitting app for trivia nights at Carbon Copy brewery.

## Project Overview

Every Monday, a group of friends goes to Carbon Copy for trivia. When one person pays the whole check, this app helps calculate what each person owes based on their items, applicable fees/taxes, and proportional tip share.

## Tech Stack

- **Framework**: Phoenix 1.7.20 with LiveView
- **Database**: PostgreSQL with Ecto
- **CSS**: Tailwind CSS
- **OCR**: Tesseract (local, free) - requires `brew install tesseract`

## Business Rules

### Item Categories & Tax Rates

| Category | Kitchen Fee | Tax Rate |
|----------|-------------|----------|
| Food | 3% (pre-tax) | 8% |
| Non-alcoholic drinks | None | 8% |
| Alcohol | None | 10% |

### Calculation Logic

For each person:
1. Sum their **food** items → apply 3% kitchen fee → apply 8% tax
2. Sum their **drink** items → apply 8% tax (no kitchen fee)
3. Sum their **alcohol** items → apply 10% tax (no kitchen fee)
4. Calculate their percentage of the total pre-tax subtotal
5. Apply that percentage to the tip amount
6. Sum everything for their total owed

### Tip Splitting

Tip is split **proportionally** based on each person's subtotal (before taxes/fees).

## User Flow

1. Upload receipt image
2. Tesseract OCR extracts text → user reviews/edits line items
3. Categorize each item (food / drink / alcohol)
4. Assign each item to one or more people
5. Enter tip amount
6. View calculated totals per person
7. Receipts are saved for history

## Database Schema

### Tables

- **people** - Friends who attend trivia (id, name)
- **receipts** - Uploaded receipts (id, image_path, tip_amount, created_at)
- **line_items** - Individual items on a receipt (id, receipt_id, name, price, category)
- **line_item_assignments** - Many-to-many between line_items and people

## Development Commands

```bash
# Start the server
mix phx.server

# Run migrations
mix ecto.migrate

# Reset database
mix ecto.reset

# Run tests
mix test
```

## OCR Setup

Tesseract must be installed locally:
```bash
brew install tesseract
```

Called from Elixir via `System.cmd("tesseract", [image_path, "stdout"])`.
