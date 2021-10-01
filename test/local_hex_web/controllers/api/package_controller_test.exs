defmodule LocalHexWeb.API.PackageControllerTest do
  use LocalHexWeb.ConnCase, async: false

  describe "#publish" do
    test "uploads and publishes new package", %{conn: conn, repository: repository} do
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

    test "with wrong auth-token return unauthorized", %{conn: conn} do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", "wrong-token")
        |> post("/api/publish", tarball)

      assert conn.status == 401
    end

    test "with wrong tarball returns bad request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> post("/api/publish", "something")

      assert conn.status == 400
    end
  end

  describe "#publish_docs" do
    test "stores new doc tarball", %{conn: conn, repository: repository} do
      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> post("/api/packages/example_lib/releases/0.1.0/docs", tarball)

      assert conn.status == 201
      assert File.exists?(path(repository, ["docs", "example_lib-0.1.0.tar"]))
    end

    test "with wrong name returns bad request", %{conn: conn} do
      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> post("/api/packages/examp+le_lib/releases/0.1.0/docs", tarball)

      assert conn.status == 400
    end

    test "with wrong version returns bad request", %{conn: conn} do
      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> post("/api/packages/example_lib/releases/0.1a.0/docs", tarball)

      assert conn.status == 400
    end
  end
end
