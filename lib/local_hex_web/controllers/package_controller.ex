defmodule LocalHexWeb.PackageController do
  use LocalHexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
