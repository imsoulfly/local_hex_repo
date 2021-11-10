defmodule LocalHex.Repository do
  @moduledoc """
  Module meant for maintaining a repository of multiple library packages.

  A `%Repository{}` struct consists of its config plus the actual list of packages and their
  releases.

  * `name` - Name of the repository as it's being stored and also accessed via the api
  * `store` - Option how the repository, registries and packages are stored (available: `:local`)
  * `registry` - Map of the registry for available packages during runtime. It's also persisted in files using the `LocalHex.Registry.Builder` module
  * `public_key` - Public key to be exposed for api usage
  * `private_key` - Private key to be kept in secret
  """

  alias LocalHex.{Documentation, Package, Storage}
  alias LocalHex.Registry
  alias LocalHex.Registry.Builder

  @manifest_vsn 1

  @derive {Inspect, only: [:name, :public_key, :store, :registry]}
  @enforce_keys [:name, :public_key, :private_key, :store]
  defstruct name: "localhex",
            store: :local,
            registry: %{},
            public_key: nil,
            private_key: nil

  def init(repository_config) do
    struct!(__MODULE__, repository_config)
  end

  def publish(repository, tarball) do
    with {:ok, package} <- Package.load_from_tarball(tarball),
         :ok <- Storage.write_package_tarball(repository, package) do
      repository =
        load(repository)
        |> Map.update!(:registry, fn registry ->
          Registry.add_package(registry, package)
        end)
        |> Builder.build_and_save(package.name)
        |> save()

      {:ok, repository}
    end
  end

  def publish_docs(repository, name, version, tarball) do
    with {:ok, documentation} <- Documentation.load(name, version, tarball),
         :ok <- Storage.write_docs_tarball(repository, documentation) do
      :ok
    end
  end

  def revert(repository, package_name, version) do
    repository = load(repository)

    if Registry.has_version?(repository.registry, package_name, version) do
      repository =
        Map.update!(repository, :registry, fn registry ->
          Registry.revert_release(registry, package_name, version)
        end)
        |> Builder.build_and_save(package_name)
        |> save()

      {:ok, repository}
    else
      {:error, :not_found}
    end
  end

  def retire(repository, package_name, version, reason, message) do
    repository = load(repository)

    if Registry.has_version?(repository.registry, package_name, version) do
      repository =
        Map.update!(repository, :registry, fn registry ->
          Registry.retire_package_release(registry, package_name, version, reason, message)
        end)
        |> Builder.build_and_save(package_name)
        |> save()

      {:ok, repository}
    else
      {:error, :not_found}
    end
  end

  def unretire(repository, package_name, version) do
    repository = load(repository)

    if Registry.has_version?(repository.registry, package_name, version) do
      repository =
        Map.update!(repository, :registry, fn registry ->
          Registry.unretire_package_release(registry, package_name, version)
        end)
        |> Builder.build_and_save(package_name)
        |> save()

      {:ok, repository}
    else
      {:error, :not_found}
    end
  end

  def save(repository) do
    contents = %{
      manifest_vsn: @manifest_vsn,
      registry: repository.registry
    }

    Storage.write_repository(repository, :erlang.term_to_binary(contents))

    repository
  end

  def load(repository) do
    registry =
      case Storage.read_repository(repository) do
        {:ok, contents} ->
          manifest_vsn = @manifest_vsn

          %{manifest_vsn: ^manifest_vsn, registry: registry} = :erlang.binary_to_term(contents)

          registry

        {:error, :not_found} ->
          %{}
      end

    %{repository | registry: registry}
  end
end
