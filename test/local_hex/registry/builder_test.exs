defmodule LocalHex.BuilderTest do
  use LocalHex.StorageCase

  alias LocalHex.Registry.Builder
  alias LocalHex.Repository

  test "#build_and_save creates persisted repository files" do
    {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
    {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

    {:ok, repository} =
      Application.fetch_env!(:local_hex, :repositories)
      |> Keyword.fetch!(:main)
      |> Repository.init()
      |> Repository.publish(tarball)

    repository = Builder.build_and_save(repository, package)

    assert File.exists?(path(repository, ["versions"]))
    assert File.exists?(path(repository, ["names"]))
    assert File.exists?(path(repository, ["packages", "example_lib"]))
  end
end
