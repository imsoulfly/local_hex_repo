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
  * `options` - Consists of additional configuration options for the mirror repository for example


  ## Explanation of options

    * `:upstream_name` - the name of the repository we are mirroring
    * `:upstream_url` - the url of the repository we are mirroring
    * `:upstream_public_key` - the public key of the repository we are mirroring
    * `:sync_opts` - options used for syncing packages and releases concurrently
       (using `Task.Supervisor.async_stream_nolink/4`). Provided options will be merged with the
       default `[ordered: false]`.
    * `:sync_interval` - how often to check mirrored repository for changes in milliseconds.
    * `:sync_mode` - (`:selective`, `:on_demand`, `:full`)
    * `:sync_only` - if set and `sync_mode == :selective` is activated, this is an allowed list of packages to mirror. If not set, we mirror all
       available packages.

       When using `:sync_only` option, you need to manually make sure that all of package's
       dependencies are included in the allowed list.

       Note, this mirror works by copying `/names` and `versions` resources from upstream.
       Thus, even though these resources may list a given package, if it's not in the allowed list it won't
       be stored in the mirror. An alternative mirror implementation could have `/names` and `/versions`
       resources only contain packages that the mirror actually has, but these resources would have
       to be signed with mirror's private key.
  """

  alias LocalHex.{Documentation, Package, Storage}
  alias LocalHex.Registry
  alias LocalHex.Registry.Builder

  @manifest_vsn 1

  @type t :: %{
          name: binary,
          store: {atom, keyword()},
          registry: map(),
          public_key: binary,
          private_key: binary,
          options: map()
        }

  @derive {Inspect, only: [:name, :public_key, :store, :registry]}
  @enforce_keys [:name, :public_key, :private_key, :store]
  defstruct name: "localhex",
            store: {LocalHex.Storage.Local, root: "priv/repos/"},
            registry: %{},
            public_key: nil,
            private_key: nil,
            options: %{}

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
    with {:ok, documentation} <- Documentation.load(name, version, tarball) do
      Storage.write_docs_tarball(repository, documentation)
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
