defmodule LocalHexWeb.PackageControllerTest do
  use LocalHexWeb.ConnCase

  alias LocalHex.Repository

  test "#index", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "For local development"
  end

  test "#show", %{conn: conn} do
    repository = repository_config()

    {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
    {:ok, _repository} = Repository.publish(repository, tarball)

    conn = get(conn, "/package/example_lib")
    assert html_response(conn, 200) =~ "/documentation/example_lib/0.1.0"
    assert html_response(conn, 200) =~ "{:example_lib, &quot;~&gt; 0.1.0&quot;, repo: :test}"
  end
end
