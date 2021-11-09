defmodule LocalHexWeb.DocumentationControllerTest do
  use LocalHexWeb.ConnCase, async: false

  alias LocalHex.Repository

  setup _tags do
    on_exit(fn ->
      Path.join([
        Application.app_dir(:local_hex),
        "priv",
        "static",
        "docs",
        repository_config().name
      ])
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

    test "returns 404 on missing lib or version", %{conn: conn} do
      conn = get(conn, "/documentation/example_lib/0.1.0")
      assert text_response(conn, 404) =~ "Document not available!"
    end
  end
end
