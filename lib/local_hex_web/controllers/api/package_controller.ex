defmodule LocalHexWeb.API.PackageController do
  use LocalHexWeb, :controller

  alias LocalHex.RepositoryServer

  # publish a package
  def publish(conn, _params) do
    {:ok, tarball, conn} = read_tarball(conn)

    case RepositoryServer.publish(repository_config(), tarball) do
      {:ok, _repository} ->
        body =
          %{"url" => Routes.url(conn)}
          |> :erlang.term_to_binary()

        conn
        |> put_resp_content_type("application/vnd.hex+erlang")
        |> send_resp(200, body)

      {:error, _} = error ->
        send_resp(conn, 400, inspect(error))
    end
  end

  def publish_docs(conn, params) do
    {:ok, tarball, conn} = read_tarball(conn)

    case RepositoryServer.publish_docs(
           repository_config(),
           params["name"],
           params["version"],
           tarball
         ) do
      :ok ->
        send_resp(conn, 201, "")

      {:error, _} = error ->
        send_resp(conn, 400, inspect(error))
    end
  end

  def revert(conn, params) do
    case RepositoryServer.revert(repository_config(), params["name"], params["version"]) do
      {:ok, _repository} ->
        send_resp(conn, 204, "")

      {:error, _} = error ->
        send_resp(conn, 400, inspect(error))
    end
  end

  def retire(conn, params) do
    case RepositoryServer.retire(
           repository_config(),
           params["name"],
           params["version"],
           params["reason"],
           params["message"]
         ) do
      {:ok, _} ->
        send_resp(conn, 201, "")

      {:error, _} = error ->
        send_resp(conn, 400, inspect(error))
    end
  end

  def unretire(conn, params) do
    case RepositoryServer.unretire(repository_config(), params["name"], params["version"]) do
      {:ok, _} ->
        send_resp(conn, 201, "")

      {:error, _} = error ->
        send_resp(conn, 400, inspect(error))
    end
  end

  defp read_tarball(conn, tarball \\ <<>>) do
    case Plug.Conn.read_body(conn) do
      {:more, partial, conn} ->
        read_tarball(conn, tarball <> partial)

      {:ok, body, conn} ->
        {:ok, tarball <> body, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
