defmodule LocalHex.RegressionTest do
  use LocalHexWeb.ConnCase

  setup do
    File.rm_rf!("tmp")
    File.rm_rf!(Path.join(Application.app_dir(:local_hex), "priv/tmp"))
    File.rm_rf!(Path.join(Application.app_dir(:local_hex), "priv/test_repos"))
    Application.ensure_all_started(:local_hex)
    :ok
  end

  test "via hex_core" do
    [main: test_repo, mirror: _] = Application.fetch_env!(:local_hex, :repositories)

    config = %{
      :hex_core.default_config()
      | repo_name: "test",
        repo_url: "http://localhost:4002",
        repo_public_key: test_repo[:public_key],
        # for publishing
        api_key: "test_token",
        api_url: "http://localhost:4002/api",
        http_adapter:
          {:hex_http_httpc,
           %{
             profile: :default,
             http_options: [
               ssl: [verify: :verify_none, reuse_sessions: false]
             ]
           }}
    }

    {:ok, {404, _, _}} = :hex_repo.get_names(config)

    # {:ok, {400, _, "{:error, {:tarball, :eof}}"}} = :hex_api_release.publish(config, "bad")
    {:ok, {400, _, _}} = :hex_api_release.publish(config, "bad")

    metadata = %{"name" => "foo", "version" => "1.0.0", "requirements" => []}
    files = [{~c"lib/foo.ex", "defmodule Foo do; end"}]

    {:ok, %{tarball: tarball, outer_checksum: outer_checksum}} =
      :hex_tarball.create(metadata, files)

    {:ok, {200, _, %{"url" => url}}} = :hex_api_release.publish(config, tarball)
    assert String.starts_with?(url, "http://localhost:4002/")

    bad_auth_config = %{config | api_key: "bad"}
    {:ok, {401, _, "unauthorized"}} = :hex_api_release.publish(bad_auth_config, tarball)
    {:ok, {401, _, _}} = :hex_api_release.publish(bad_auth_config, tarball)

    {:ok, {200, _, packages}} = :hex_repo.get_names(config)
    assert packages == %{packages: [%{name: "foo"}], repository: "test"}

    {:ok, {200, _, packages}} = :hex_repo.get_versions(config)

    assert packages == %{
             packages: [%{name: "foo", retired: [], versions: ["1.0.0"]}],
             repository: "test"
           }

    {:ok, {200, _, %{releases: [release]}}} = :hex_repo.get_package(config, "foo")
    assert release.outer_checksum == outer_checksum

    assert {:ok, {200, _, ^tarball}} = :hex_repo.get_tarball(config, "foo", "1.0.0")

    {:ok, {201, _, _}} =
      :hex_api_release.retire(config, "foo", "1.0.0", %{
        "reason" => "security",
        "message" => "CVE-2019-0000"
      })

    {:ok, {200, _, packages}} = :hex_repo.get_versions(config)

    assert packages == %{
             packages: [%{name: "foo", retired: [0], versions: ["1.0.0"]}],
             repository: "test"
           }

    {:ok, {200, _, %{releases: [release]}}} = :hex_repo.get_package(config, "foo")
    assert release.retired == %{message: "CVE-2019-0000", reason: :RETIRED_SECURITY}

    {:ok, {201, _, _}} = :hex_api_release.unretire(config, "foo", "1.0.0")
    {:ok, {200, _, packages}} = :hex_repo.get_versions(config)

    assert packages == %{
             packages: [%{name: "foo", retired: [], versions: ["1.0.0"]}],
             repository: "test"
           }
  end
end
