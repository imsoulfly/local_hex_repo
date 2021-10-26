defmodule LocalHex.RegressionTest do
  use ExUnit.Case

  alias LocalHexWeb.Router.Helpers, as: Routes

  setup do
    File.rm_rf!("tmp")
    File.rm_rf!(Path.join(Application.app_dir(:local_hex), "priv/tmp"))
    File.rm_rf!(Path.join(Application.app_dir(:local_hex), "priv/test_repos"))
    Application.ensure_all_started(:local_hex)
    :ok
  end

  test "via hex_core" do
    [main: test_repo] = Application.fetch_env!(:local_hex, :repositories)

    config = %{
      :hex_core.default_config()
      | repo_name: "test",
        repo_url: "http://localhost:4002",
        repo_public_key: test_repo[:public_key],
        # for publishing
        api_key: "test_token",
        api_url: "http://localhost:4002/api"
    }

    {:ok, {404, _, _}} = :hex_repo.get_names(config)

    # TODO:
    # {:ok, {400, _, "{:error, {:tarball, :eof}}"}} = :hex_api_release.publish(config, "bad")
    {:ok, {400, _, _}} = :hex_api_release.publish(config, "bad")

    metadata = %{"name" => "foo", "version" => "1.0.0", "requirements" => []}
    files = [{'lib/foo.ex', "defmodule Foo do; end"}]

    {:ok, %{tarball: tarball, outer_checksum: outer_checksum}} =
      :hex_tarball.create(metadata, files)

    {:ok, {200, _, %{"url" => url}}} = :hex_api_release.publish(config, tarball)
    assert url == Routes.url(LocalHexWeb.Endpoint)

    bad_auth_config = %{config | api_key: "bad"}
    {:ok, {401, _, "unauthorized"}} = :hex_api_release.publish(bad_auth_config, tarball)
    {:ok, {401, _, _}} = :hex_api_release.publish(bad_auth_config, tarball)

    {:ok, {200, _, packages}} = :hex_repo.get_names(config)
    assert packages == [%{name: "foo"}]

    {:ok, {200, _, packages}} = :hex_repo.get_versions(config)

    assert packages == [%{name: "foo", retired: [], versions: ["1.0.0"]}]

    {:ok, {200, _, [release]}} = :hex_repo.get_package(config, "foo")
    assert release.outer_checksum == outer_checksum

    assert {:ok, {200, _, ^tarball}} = :hex_repo.get_tarball(config, "foo", "1.0.0")

    # TODO: for later waiting for retire, unretire, delete
    # {:ok, {201, _, _}} =
    #   :hex_api_release.retire(config, "foo", "1.0.0", %{
    #     "reason" => "security",
    #     "message" => "CVE-2019-0000"
    #   })

    # {:ok, {200, _, packages}} = :hex_repo.get_versions(config)
    # assert packages == [%{name: "foo", retired: [0], versions: ["1.0.0"]}]

    # {:ok, {200, _, [release]}} = :hex_repo.get_package(config, "foo")
    # assert release.retired == %{message: "CVE-2019-0000", reason: :RETIRED_SECURITY}

    # {:ok, {201, _, _}} = :hex_api_release.unretire(config, "foo", "1.0.0")
    # {:ok, {200, _, packages}} = :hex_repo.get_versions(config)
    # assert packages == [%{name: "foo", retired: [], versions: ["1.0.0"]}]

    # # restart application, load registry from backup
    # Application.stop(:local_hex)
    # Application.start(:local_hex)

    # {:ok, {200, _, packages}} = :hex_repo.get_names(config)
    # assert packages == [%{name: "foo"}]

    # assert {:ok, {201, _, _}} = publish_docs(config, "foo", "1.0.0", {'text/plain', "foo"})
    # assert {:ok, {200, _, "foo"}} = get_docs(config, "foo", "1.0.0")

    # {:ok, {204, _, _}} = :hex_api_release.delete(config, "foo", "1.0.0")

    # {:ok, {200, _, packages}} = :hex_repo.get_names(config)
    # assert packages == []
  end
end