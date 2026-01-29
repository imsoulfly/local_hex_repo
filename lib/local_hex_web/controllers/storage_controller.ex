defmodule LocalHexWeb.StorageController do
  use LocalHexWeb, :controller

  alias LocalHex.Mirror.Server
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
    name = params["name"]
    repo = repository_config()

    case Storage.read_package(repo, name) do
      {:ok, contents} ->
        send_hex(conn, contents)

      {:error, _} ->
        send_mirrored_package(conn, name)
    end
  end

  def tarball(conn, params) do
    tarball = params["tarball"]
    repo = repository_config()

    case Storage.read_package_tarball(repo, tarball) do
      {:ok, contents} ->
        send_hex(conn, contents)

      {:error, _} ->
        send_mirrored_tarball(conn, tarball)
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

  defp send_hex(conn, contents) do
    conn
    |> put_resp_content_type("application/vnd.hex+erlang")
    |> send_resp(200, contents)
  end

  defp send_mirrored_package(conn, name) do
    case repository_mirror_config() do
      nil ->
        send_resp(conn, 404, "")

      mirror_repo ->
        Server.ensure_package(name)

        case Storage.read_package(mirror_repo, name) do
          {:ok, contents} -> send_hex(conn, contents)
          {:error, _} -> send_resp(conn, 404, "")
        end
    end
  end

  defp send_mirrored_tarball(conn, tarball) do
    with mirror_repo when not is_nil(mirror_repo) <- repository_mirror_config(),
         {:ok, contents} <- Storage.read_package_tarball(mirror_repo, tarball) do
      send_hex(conn, contents)
    else
      _ -> send_resp(conn, 404, "")
    end
  end
end
