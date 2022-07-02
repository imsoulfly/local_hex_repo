defmodule LocalHex.Mirror.Sync do
  @moduledoc """
  The `Mirror.Sync` module is meant to keep a local repositorys data in sync with another (upstream) repository.
  That normally should be hex.pm but could be any oter repository that applies the hex api.pm

  For the synchronisation several steps are needed to keep the data sane:

  1. Filter for allowed packages
  We can configure a repository to only sync certain packagages including versions and we need to make sure to
  keep our local repo clean as well as the downloaded packages during the synchronisation

  2. Creating a diff between local and upstream repos
  Many things can happen to a repositorys data like creation, deletion, deprecation etc.
  To keep the same state in the mirrored version we need to provide a diff for the following
  states a package version can be in.

  - :created
  - :deleted
  - :retired
  -


  ## Short example for payload formats

  ### Names

  ```
  [
    %{name: "absinthe", updated_at: %{nanos: 820498000, seconds: 1642619042}},
    %{
      name: "absinthe_auth",
      updated_at: %{nanos: 101485000, seconds: 1538902145}
    },
    ...
  ]
  ```

  ### Versions

  ```
  [
    %{
       name: "absinthe",
       retired: '?e',
       versions: ["0.1.0", "0.2.1", "0.2.2", "0.2.3", "0.4.0", "0.4.1", "0.4.2",
        "0.4.3", "0.4.4", "0.4.5", "0.4.6", "0.5.0", "0.5.1", "0.5.2", "1.0.0",
        "1.1.0", "1.1.1", "1.1.2", "1.1.3", "1.1.4", "1.1.5", "1.1.6", ...]
     },
     %{
       name: "absinthe_auth",
       retired: [],
       versions: ["0.1.0", "0.1.1", "0.2.0", "0.2.1"]
     },
     ...
   ]
  ```

  ### Package

  A package consists of a list of versions of the package and it's dependencies
  ```
  [
     %{
       dependencies: [
         %{optional: true, package: "decimal", requirement: "~> 1.0"}
       ],
       inner_checksum: <<200, 66, 29, 78, 110, 110, 240, 221, 124, 43, 100, 255,
         99, 88, 159, 133, 97, 17, 104, 8, 250, 0, 61, 221, 253, 83, 96, 205, 231,
         187, 70, 37>>,
       outer_checksum: <<157, 73, 129, 3, 242, 145, 156, 200, 208, 187, 143, 59,
         95, 44, 211, 110, 52, 23, 4, 176, 180, 198, 37, 162, 255, 245, 156, 162,
         15, 247, 71, 41>>,
       version: "1.0.0-rc.1"
     },
     ...
   ]
  ```
  """

  require Logger

  alias LocalHex.Mirror.HexApi
  alias LocalHex.Mirror.RegistryDiff
  alias LocalHex.Package
  alias LocalHex.Repository
  alias LocalHex.Storage

  @default_sync_opts [ordered: false]

  def sync(mirror, new_package_name \\ nil) do
    with {:ok, names} when is_list(names) <- sync_names(mirror),
         {:ok, versions} when is_list(versions) <- sync_versions(mirror) do
      versions = filter_allowed_packages(mirror, versions, new_package_name)
      difference = RegistryDiff.compare(mirror.registry, versions)

      Logger.debug([inspect(__MODULE__), " difference: ", inspect(difference, pretty: true)])
      created = sync_created_packages(mirror, difference)
      deleted = sync_deleted_packages(mirror, difference)
      updated = sync_releases(mirror, difference)

      mirror =
        update_in(mirror.registry, fn registry ->
          registry
          |> Enum.reject(fn {key, _} -> key in deleted end)
          |> Enum.into(%{})
          |> Map.merge(created)
          |> Map.merge(updated)
        end)

      Repository.save(mirror)
      {:ok, mirror}
    end
  end

  defp filter_allowed_packages(mirror, versions, new_package_name) do
    packages_in_registry = Map.keys(mirror.registry)

    for %{name: name} = map <- versions,
        name in packages_in_registry or
          name in mirror.options[:sync_only] or
          name == new_package_name,
        into: %{},
        do: {name, Map.delete(map, :version)}
  end

  defp sync_created_packages(mirror, diff) do
    Logger.debug("#{inspect(__MODULE__)} sync_created_packages #{inspect(diff)}")
    mirror_sync_opts = Keyword.merge(@default_sync_opts, mirror.options.sync_opts)

    stream =
      Task.Supervisor.async_stream_nolink(
        LocalHex.TaskSupervisor,
        diff.packages.created,
        fn name ->
          Logger.debug("#{inspect(__MODULE__)} syncing #{name}")

          {:ok, releases} = sync_package(mirror, name)

          stream =
            Task.Supervisor.async_stream_nolink(
              LocalHex.TaskSupervisor,
              releases,
              fn release ->
                :ok = sync_tarball(mirror, name, release.version)
                release
              end,
              mirror_sync_opts
            )

          releases = for {:ok, release} <- stream, do: release
          {name, releases}
        end,
        mirror_sync_opts
      )

    for {:ok, {name, releases}} <- stream, into: %{} do
      {name, releases}
    end
  end

  defp sync_deleted_packages(mirror, diff) do
    Logger.debug("#{inspect(__MODULE__)} sync_deleted_packages")

    for name <- diff.packages.deleted do
      for %{version: version} <- mirror.registry[name] do
        Storage.delete_package_tarball(mirror, "#{name}-#{version}.tar")
      end

      Storage.delete_package(mirror, name)

      name
    end
  end

  defp sync_releases(mirror, diff) do
    Logger.debug("#{inspect(__MODULE__)} sync_releases")
    mirror_sync_opts = Keyword.merge(@default_sync_opts, mirror.options.sync_opts)

    stream =
      Task.Supervisor.async_stream_nolink(
        LocalHex.TaskSupervisor,
        diff.releases,
        fn {name, map} ->
          {:ok, releases} = sync_package(mirror, name)

          Task.Supervisor.async_stream_nolink(
            LocalHex.TaskSupervisor,
            map.created,
            fn version ->
              :ok = sync_tarball(mirror, name, version)
            end,
            mirror_sync_opts
          )
          |> Stream.run()

          for version <- map.deleted do
            Storage.delete(mirror, "#{name}-#{version}.tar")
          end

          {name, releases}
        end,
        mirror_sync_opts
      )

    for {:ok, {name, releases}} <- stream, into: %{} do
      {name, releases}
    end
  end

  defp sync_names(mirror) do
    with {:ok, signed} <- HexApi.fetch_hexpm_names(mirror),
         {:ok, names} <- decode_hexpm_names(mirror, signed),
         signed_names <- encode_names(mirror, names),
         :ok <- Storage.write_names(mirror, signed_names) do
      {:ok, names}
    else
      other ->
        Logger.warn("#{inspect(__MODULE__)} sync_names failed: #{inspect(other)}")
        other
    end
  end

  defp sync_versions(mirror) do
    with {:ok, signed} <- HexApi.fetch_hexpm_versions(mirror),
         {:ok, versions} <- decode_hexpm_versions(mirror, signed),
         signed_versions <- encode_versions(mirror, versions),
         :ok <- Storage.write_versions(mirror, signed_versions) do
      {:ok, versions}
    else
      other ->
        Logger.warn("#{inspect(__MODULE__)} sync_versions failed: #{inspect(other)}")
        other
    end
  end

  defp sync_package(mirror, name) do
    with {:ok, signed} <- HexApi.fetch_hexpm_package(mirror, name),
         {:ok, package} <- decode_hexpm_package(mirror, signed, name),
         signed_package <- encode_package(mirror, name, package),
         :ok <- Storage.write_package(mirror, name, signed_package) do
      {:ok, package}
    else
      other ->
        Logger.warn("#{inspect(__MODULE__)} sync_package failed: #{inspect(other)}")
        other
    end
  end

  defp sync_tarball(mirror, name, version) do
    with {:ok, tarball} <- HexApi.fetch_hexpm_tarball(mirror, name, version),
         {:ok, package} <- Package.load_from_tarball(tarball),
         :ok <- Storage.write_package_tarball(mirror, package) do
      :ok
    else
      other ->
        Logger.warn("#{inspect(__MODULE__)} sync_tarball failed: #{inspect(other)}")
        other
    end
  end

  defp encode_names(repository, names) do
    protobuf =
      :hex_registry.encode_names(%{
        repository: repository.name,
        packages: names
      })

    sign_and_gzip(repository, protobuf)
  end

  defp encode_versions(repository, versions) do
    protobuf =
      :hex_registry.encode_versions(%{
        repository: repository.name,
        packages: versions
      })

    sign_and_gzip(repository, protobuf)
  end

  defp encode_package(repository, name, package) do
    protobuf =
      :hex_registry.encode_package(%{
        repository: repository.name,
        name: name,
        releases: package
      })

    sign_and_gzip(repository, protobuf)
  end

  defp sign_and_gzip(repository, protobuf) do
    protobuf
    |> :hex_registry.sign_protobuf(repository.private_key)
    |> :zlib.gzip()
  end

  defp decode_hexpm_names(repository, body) do
    {:ok, payload} = decode_and_verify_signed(body, repository)
    :hex_registry.decode_names(payload, repository.options.upstream_name)
  end

  defp decode_hexpm_versions(repository, body) do
    {:ok, payload} = decode_and_verify_signed(body, repository)
    :hex_registry.decode_versions(payload, repository.options.upstream_name)
  end

  defp decode_hexpm_package(repository, body, name) do
    {:ok, payload} = decode_and_verify_signed(body, repository)
    :hex_registry.decode_package(payload, repository.options.upstream_name, name)
  end

  defp decode_and_verify_signed(body, repository) do
    body
    |> :zlib.gunzip()
    |> :hex_registry.decode_and_verify_signed(repository.options.upstream_public_key)
  end
end
