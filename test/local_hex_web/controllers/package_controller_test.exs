defmodule LocalHexWeb.PackageControllerTest do
  use LocalHexWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "For local development"
  end
end
