defmodule CarbonCopCheckAppWeb.PageControllerTest do
  use CarbonCopCheckAppWeb.ConnCase

  test "GET / redirects to receipts", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/receipts"
  end
end
