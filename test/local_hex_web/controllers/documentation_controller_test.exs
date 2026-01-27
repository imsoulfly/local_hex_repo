defmodule LocalHexWeb.DocumentationControllerTest do
  use LocalHexWeb.ConnCase, async: false

  alias LocalHex.Repository

  setup _tags do
    on_exit(fn ->
      base =
        System.get_env("LOCAL_HEX_DOCS_CACHE_DIR") ||
          Application.app_dir(:local_hex, "priv/static/docs")

      Path.join([base, repository_config().name])
      |> File.rm_rf()
    end)

    :ok
  end

  describe "#show" do
    test "redirects to static cache version of documentation", %{conn: conn} do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
      :ok = Repository.publish_docs(repository, "example_lib", "0.1.0", tarball)

      conn = get(conn, "/documentation/example_lib/0.1.0")
      assert html_response(conn, 302) =~ "/docs/test/example_lib-0.1.0/index.html"
      assert html_response(conn, 302) =~ "redirected"
    end

    test "serves docs from LOCAL_HEX_DOCS_CACHE_DIR when set", %{conn: conn} do
      tmp_dir =
        Path.join(System.tmp_dir!(), "local_hex_docs_test_#{System.unique_integer([:positive])}")

      File.mkdir_p!(tmp_dir)
      System.put_env("LOCAL_HEX_DOCS_CACHE_DIR", tmp_dir)

      on_exit(fn ->
        System.delete_env("LOCAL_HEX_DOCS_CACHE_DIR")
        File.rm_rf(tmp_dir)
      end)

      repository = repository_config()
      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
      :ok = Repository.publish_docs(repository, "example_lib", "0.1.0", tarball)

      conn = get(conn, "/documentation/example_lib/0.1.0")

      [location] = Plug.Conn.get_resp_header(conn, "location")
      assert location == "/docs/test/example_lib-0.1.0/index.html"

      conn = build_conn() |> get(location)
      assert conn.status == 200

      conn = build_conn() |> get("/docs/test/example_lib-0.1.0/docs_config.js")
      assert conn.status == 200
      assert conn.resp_body =~ "var versionNodes"
    end

    test "returns 404 on missing lib or version", %{conn: conn} do
      conn = get(conn, "/documentation/example_lib/0.1.0")
      assert text_response(conn, 404) =~ "Document not available!"
    end
  end
end
