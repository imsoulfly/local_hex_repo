defmodule LocalHexWeb.StorageControllerTest do
  use LocalHexWeb.ConnCase, async: false

  alias LocalHex.{Repository, Storage}

  describe "#names" do
    test "loads names of repository", %{conn: conn, repository: repository} do
      value = "test_string"
      Storage.write_names(repository, value)

      conn = get(conn, "/names")

      assert conn.status == 200
      assert conn.resp_body == value
    end

    test "with nonexisting repository names returns not found", %{conn: conn} do
      conn = get(conn, "/names")

      assert conn.status == 404
    end
  end

  describe "#versions" do
    test "loads versions of repository", %{conn: conn, repository: repository} do
      value = "test_string"
      Storage.write_versions(repository, value)

      conn = get(conn, "/versions")

      assert conn.status == 200
      assert conn.resp_body == value
    end

    test "with nonexisting repository versions returns not found", %{conn: conn} do
      conn = get(conn, "/versions")

      assert conn.status == 404
    end
  end

  describe "#package" do
    test "loads package", %{conn: conn, repository: repository} do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, _} = Repository.publish(repository, tarball)

      conn = get(conn, "/packages/example_lib")

      assert conn.status == 200
    end

    test "with nonexisting package returns not found", %{conn: conn} do
      conn = get(conn, "/packages/example_lib")

      assert conn.status == 404
    end
  end

  describe "#package_tarball" do
    test "loads package tarball ", %{conn: conn, repository: repository} do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, _} = Repository.publish(repository, tarball)

      conn = get(conn, "/tarballs/example_lib-0.1.0.tar")

      assert conn.status == 200
    end

    test "with nonexisting package tarball returns not found", %{conn: conn} do
      conn = get(conn, "/tarballs/example_lib-0.1.0.tar")

      assert conn.status == 404
    end
  end

  describe "#docs_tarball" do
    test "loads documentation tarball ", %{conn: conn, repository: repository} do
      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
      :ok = Repository.publish_docs(repository, "example_lib", "0.1.0", tarball)

      conn = get(conn, "/docs/example_lib-0.1.0.tar")

      assert conn.status == 200
    end

    test "with nonexisting documentation tarball returns not found", %{conn: conn} do
      conn = get(conn, "/docs/example_lib-0.1.0.tar")

      assert conn.status == 404
    end
  end
end
