defmodule LocalHexWeb.API.PackageControllerTest do
  use LocalHexWeb.ConnCase, async: false

  test "#publish uploads and publishes new package", %{conn: conn, repository: repository} do
    {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")

    conn =
      conn
      |> put_req_header("content-type", "application/octet-stream")
      |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
      |> post("/api/publish", tarball)

    assert conn.status == 200
    assert File.exists?(path(repository, ["versions"]))
    assert File.exists?(path(repository, ["names"]))
    assert File.exists?(path(repository, ["tarballs", "example_lib-0.1.0.tar"]))
    assert File.exists?(path(repository, ["packages", "example_lib"]))
  end

  test "#publish with wrong auth-token return unauthorized", %{conn: conn} do
    {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")

    conn =
      conn
      |> put_req_header("content-type", "application/octet-stream")
      |> put_req_header("authorization", "wrong-token")
      |> post("/api/publish", tarball)

    assert conn.status == 401
  end

  test "#publish with wrong tarball returns bad request", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/octet-stream")
      |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
      |> post("/api/publish", "something")

    assert conn.status == 400
  end
end
