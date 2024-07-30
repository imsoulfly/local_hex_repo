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
      assert File.exists?(file_path(repository, ["versions"]))
      assert File.exists?(file_path(repository, ["names"]))
      assert File.exists?(file_path(repository, ["tarballs", "example_lib", "example_lib-0.1.0.tar"]))
      assert File.exists?(file_path(repository, ["packages", "example_lib"]))
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
      assert File.exists?(file_path(repository, ["docs", "example_lib", "example_lib-0.1.0.tar"]))
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

  describe "#retire" do
    test "marks a release as retired", %{conn: conn} do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> post("/api/packages/example_lib/releases/0.1.0/retire", %{
          reason: "invalid",
          message: "some_message"
        })

      assert conn.status == 201

      repository = LocalHex.Repository.load(repository)
      result = repository.registry["example_lib"] |> List.first()

      expected_retired = %{
        reason: :RETIRED_INVALID,
        message: "some_message"
      }

      assert Map.has_key?(result, :retired)
      assert ^expected_retired = result.retired
    end

    test "error on missing version", %{conn: conn} do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, _} = LocalHex.Repository.publish(repository, tarball)

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> post("/api/packages/example_lib/releases/0.2.0/retire", %{
          reason: "invalid",
          message: "some_message"
        })

      assert conn.status == 400
    end
  end

  describe "#unretire" do
    test "removes a :retired entry from a release", %{conn: conn} do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)

      {:ok, repository} =
        LocalHex.Repository.retire(repository, "example_lib", "0.1.0", "invalid", "some_message")

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> delete("/api/packages/example_lib/releases/0.1.0/retire")

      assert conn.status == 201

      repository = LocalHex.Repository.load(repository)
      result = repository.registry["example_lib"] |> List.first()

      refute Map.has_key?(result, :retired)
    end

    test "error on missing version", %{conn: conn} do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)

      {:ok, _} =
        LocalHex.Repository.retire(repository, "example_lib", "0.1.0", "invalid", "some_message")

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> delete("/api/packages/example_lib/releases/0.2.0/retire")

      assert conn.status == 400
    end
  end

  describe "#revert" do
    test "removes a release from repository", %{conn: conn} do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> delete("/api/packages/example_lib/releases/0.1.0")

      assert conn.status == 204

      repository = LocalHex.Repository.load(repository)

      assert Enum.empty?(repository.registry["example_lib"])
    end

    test "error on missing version", %{conn: conn} do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, _repository} = LocalHex.Repository.publish(repository, tarball)

      conn =
        conn
        |> put_req_header("content-type", "application/octet-stream")
        |> put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
        |> delete("/api/packages/example_lib/releases/0.2.0")

      assert conn.status == 400
    end
  end
end
