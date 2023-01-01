defmodule LocalHex.MirrorCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias LocalHex.Package
  alias LocalHex.Registry
  alias LocalHex.Repository
  alias LocalHex.Storage

  using do
    quote do
      alias LocalHex.Mirror.MockHexApi
      alias LocalHex.Mirror.Sync
      alias LocalHex.Package
      alias LocalHex.Repository

      import LocalHex.MirrorCase
    end
  end

  setup _tags do
    on_exit(fn ->
      repository = repository()

      root_path(repository.store)
      |> File.rm_rf()
    end)

    :ok
  end

  def repository(sync_only \\ []) do
    Repository.init(
      name: "local_hex_test_mirror",
      store: {LocalHex.Storage.Local, root: "priv/repos/"},
      private_key: File.read!(Path.expand("../../test/fixtures/test_private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../../test/fixtures/test_public_key.pem", __DIR__)),
      options: %{
        # sync_interval: 5 * 60 * 1000,
        sync_interval: 100 * 1000,
        sync_opts: [max_concurrency: 5, timeout: 20_000],
        sync_only: sync_only,

        # Source: https://hex.pm/docs/public_keys
        upstream_name: "hexpm",
        upstream_url: "https://repo.hex.pm",
        # Let's simulate this with the same private key for now
        upstream_public_key:
          File.read!(Path.expand("../../test/fixtures/test_public_key.pem", __DIR__))
      }
    )
    |> Repository.load()
    |> Repository.save()
    |> Repository.load()
  end

  def path(repository, path) do
    Path.join([root_path(repository.store), repository.name | List.wrap(path)])
  end

  def root_path({_module, root: path}) do
    Path.join(Application.app_dir(:local_hex), path)
  end

  def upstream_encode_names(names) do
    :hex_registry.encode_names(%{
      repository: repository().options.upstream_name,
      packages: names
    })
    |> :hex_registry.sign_protobuf(repository().private_key)
    |> :zlib.gzip()
  end

  def upstream_encode_versions(versions) do
    :hex_registry.encode_versions(%{
      repository: repository().options.upstream_name,
      packages: versions
    })
    |> :hex_registry.sign_protobuf(repository().private_key)
    |> :zlib.gzip()
  end

  def upstream_encode_package(name, packages) do
    :hex_registry.encode_package(%{
      repository: repository().options.upstream_name,
      name: name,
      releases:
        for p <- packages do
          p.release
        end
    })
    |> :hex_registry.sign_protobuf(repository().private_key)
    |> :zlib.gzip()
  end

  def initial_repository_setup do
    names =
      [
        %{name: "example_lib", updated_at: %{nanos: 820_498_000, seconds: 1_642_619_042}}
      ]
      |> upstream_encode_names()

    versions =
      [
        %{
          name: "example_lib",
          retired: [],
          versions: ["0.1.0", "0.2.0"]
        }
      ]
      |> upstream_encode_versions()

    {:ok, tarball1} = File.read("./test/fixtures/example_lib-0.1.0.tar")
    {:ok, tarball2} = File.read("./test/fixtures/example_lib-0.2.0.tar")

    {:ok, package1} = Package.load_from_tarball(tarball1)
    {:ok, package2} = Package.load_from_tarball(tarball2)

    package = upstream_encode_package("example_lib", [package1, package2])

    repository = Repository.load(repository())

    registry =
      repository.registry
      |> Registry.add_package(package1)
      |> Registry.add_package(package2)

    repository = %{repository | registry: registry}
    Repository.save(repository)

    Storage.write_names(repository(), names)
    Storage.write_versions(repository(), versions)
    Storage.write_package(repository(), "example_lib", package)
    Storage.write_package_tarball(repository(), package1)
    Storage.write_package_tarball(repository(), package2)
  end
end
