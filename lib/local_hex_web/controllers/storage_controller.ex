defmodule LocalHexWeb.StorageController do
  use LocalHexWeb, :controller

  alias LocalHex.{Repository, Storage}

  def names(conn, _params) do
    case Storage.read_names(repository_config()) do
      {:ok, contents} ->
        conn
        |> send_resp(200, contents)

      {:error, _} ->
        send_resp(conn, 404, "")
    end
  end

  def versions(conn, _params) do
    case Storage.read_versions(repository_config()) do
      {:ok, contents} ->
        conn
        |> send_resp(200, contents)

      {:error, _} ->
        send_resp(conn, 404, "")
    end
  end

  def package(conn, params) do
    case Storage.read_package(repository_config(), params["name"]) do
      {:ok, contents} ->
        conn
        |> put_resp_content_type("application/vnd.hex+erlang")
        |> send_resp(200, contents)

      {:error, _} ->
        send_resp(conn, 404, "")
    end
  end

  def tarball(conn, params) do
    case Storage.read_package_tarball(repository_config(), params["tarball"]) do
      {:ok, contents} ->
        conn
        |> put_resp_content_type("application/vnd.hex+erlang")
        |> send_resp(200, contents)

      {:error, _} ->
        send_resp(conn, 404, "")
    end
  end

  def docs_tarball(conn, params) do
    case Storage.read_docs_tarball(repository_config(), params["tarball"]) do
      {:ok, contents} ->
        conn
        |> put_resp_content_type("application/vnd.hex+erlang")
        |> send_resp(200, contents)

      {:error, _} ->
        send_resp(conn, 404, "")
    end
  end

  def public_key(conn, _params) do
    repository = repository_config()

    conn
    |> put_resp_content_type("application/x-pem-file")
    |> put_resp_header("content-disposition", "attachment; filename=\"public_key.pem\"")
    |> send_resp(200, repository.public_key)
  end

  defp repository_config do
    Application.fetch_env!(:local_hex, :repositories)
    |> Keyword.fetch!(:main)
    |> Repository.init()
  end
end
