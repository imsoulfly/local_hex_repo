defmodule LocalHex.Repository do
  @moduledoc """
  Module meant for maintaining a repository of multiple library packages.

  A `%Repository{}` struct consists of the its config plus the actual list of packages and their
  releases.

  * `name` - Name of the repository as it's being stored and also accessed via the api
  * `store` - Option how the repository, registries and packages are stored (available: `:local`)
  * `registry` - Map of the registry for available packages during runtime. It's also persisted in files using the `LocalHex.Registry.Builder` module
  * `public_key` - Public key to be exposed for api usage
  * `private_key` - Private key to be kept in secret
  """

  alias LocalHex.{Package, Storage}
  alias LocalHex.Registry
  alias LocalHex.Registry.Builder

  @manifest_vsn 1

  @derive {Inspect, only: [:name, :public_key, :store, :registry]}
  @enforce_keys [:name, :public_key, :private_key, :store]
  defstruct [
    name: "localhex",
    store: :local,
    registry: %{},
    public_key: nil,
    private_key: nil
  ]

  def init(repository_config) do
    struct!(__MODULE__, repository_config)
  end

  def publish(repository, tarball) do
    with {:ok, package} <- Package.load_from_tarball(tarball),
         :ok <- Storage.write(repository, package) do

      repository =
        load(repository)
        |> Map.update!(:registry, fn registry ->
          Registry.add_package(registry, package)
        end)
        |> Builder.build_and_save(package)
        |> save()

      {:ok, repository}
    end
  end

  def save(repository) do
    contents = %{
      manifest_vsn: @manifest_vsn,
      registry: repository.registry
    }

    Storage.write(repository, repository_path(repository), :erlang.term_to_binary(contents))

    repository
  end

  def load(repository) do
    registry =
      case Storage.read(repository, repository_path(repository)) do
        {:ok, contents} ->
          manifest_vsn = @manifest_vsn

          %{manifest_vsn: ^manifest_vsn, registry: registry} = :erlang.binary_to_term(contents)

          registry

        {:error, :not_found} ->
          %{}
      end

    %{repository | registry: registry}
  end

  defp repository_path(repository) do
    repository.name <> ".bin"
  end
end
