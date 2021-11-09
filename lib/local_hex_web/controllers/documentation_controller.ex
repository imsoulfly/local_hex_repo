defmodule LocalHexWeb.DocumentationController do
  use LocalHexWeb, :controller

  alias LocalHex.Documentation.Cache

  def show(conn, params) do
    case Cache.cache_path(repository_config(), params) do
      {:ok, path} ->
        redirect(conn, to: path)

      {:error, _msg} ->
        conn
        |> put_status(404)
        |> text("Document not available!")
    end
  end
end
