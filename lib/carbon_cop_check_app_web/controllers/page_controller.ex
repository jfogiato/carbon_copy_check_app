defmodule CarbonCopCheckAppWeb.PageController do
  use CarbonCopCheckAppWeb, :controller

  alias CarbonCopCheckApp.Receipts

  def home(conn, _params) do
    recent_receipts = Receipts.list_receipts() |> Enum.take(3)
    people_count = Receipts.list_people() |> length()

    render(conn, :home,
      layout: {CarbonCopCheckAppWeb.Layouts, :app},
      recent_receipts: recent_receipts,
      people_count: people_count
    )
  end
end
