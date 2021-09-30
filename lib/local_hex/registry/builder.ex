defmodule LocalHex.Registry.Builder do
  @moduledoc """
  The `Registry.Builder` module is used to persit the registry of a repository in signed files using using
  `:hex_core` library

  The stored files are:

  * `names` - signed file storing a list of available package names
  * `versions` - signed file storing a list of available versions for all packages
  * `packages` - signed file storing a list of packages
  * `public_key` - file for the public key

  __Format of `names`__

  ```
  %{
    repository: "local_hex",
    packages: [
      %{name: "package_1"},
      %{name: "package_2"},
      ...
    ]
  }
  ```

  __Format of `versions`__

  ```
  %{
    repository: "local_hex",
    packages: [
      %{
        name: "package_1",
        versions: [
          "0.0.1",
          "0.0.2",
        ]
      },
      %{
        name: "package_2",
        versions: [
          "0.0.1",
          "0.0.2",
        ]
        retired: [1]
        },

      ...
    ]
  }
  ```

  __Format of `packags`__
  Known representation from the runtime `LocalHex.Registry`

  ```
  %{
    repository: "local_hex",
    packages: %{
      "package_1" => [
        %{
          version: "0.0.1"
        },
        %{
          version: "0.0.2"
        }
      ],
      "package_2" => [
        %{
          version: "0.0.1"
          retired: %{
            reason: :RETIRED_OTHER | :RETIRED_INVALID | :RETIRED_SECURITY | :RETIRED_DEPRECATED | :RETIRED_RENAMED,
            message: "Please update to newer version"
          }
        },
        %{
          version: "0.0.2"
        },
        ...
      ],
      ...
    }
  }
  ```
  """

  alias LocalHex.Storage

  def build_and_save(repository, package) do
    resources = build_partial(repository, package.name)

    for {name, content} <- resources do
      Storage.write(repository, [name], content)
    end

    repository
  end

  def build_partial(repository, package_name) do
    resources = %{
      "names" => build_names(repository),
      "versions" => build_versions(repository)
    }

    case Map.fetch(repository.registry, package_name) do
      {:ok, releases} ->
        Map.put(resources, Path.join(["packages", package_name]), build_package(repository, package_name, releases))

      # release is being reverted
      :error ->
        resources
    end
  end

  def build_names(repository) do
    packages = for {name, _releases} <- repository.registry, do: %{name: name}
    protobuf = :hex_registry.encode_names(%{repository: repository.name, packages: packages})
    sign_and_gzip(repository, protobuf)
  end

  def build_versions(repository) do
    packages =
      for {name, releases} <- Enum.sort_by(repository.registry, &elem(&1, 0)) do
        versions =
          releases
          |> Enum.map(& &1.version)
          |> Enum.sort(&(Version.compare(&1, &2) == :lt))
          |> Enum.uniq()

        package = %{name: name, versions: versions}
        Map.put(package, :retired, retired_index(releases))
      end

    protobuf = :hex_registry.encode_versions(%{repository: repository.name, packages: packages})
    sign_and_gzip(repository, protobuf)
  end

  def build_package(repository, name, releases) do
    protobuf =
      :hex_registry.encode_package(%{repository: repository.name, name: name, releases: releases})

    sign_and_gzip(repository, protobuf)
  end

  defp retired_index(releases) do
    for {release, index} <- Enum.with_index(releases),
        match?(%{retired: %{reason: _}}, release) do
      index
    end
  end

  defp sign_and_gzip(repository, protobuf) do
    protobuf
    |> :hex_registry.sign_protobuf(repository.private_key)
    |> :zlib.gzip()
  end
end
