defmodule LocalHex.Package do
  @moduledoc false
  require Logger

  defstruct [:name, :version, :release, :tarball]

  def load_from_filename(name) do
    name_regex = ~r/\A(?<package_name>.*)-(?<version>\d\.\d\.\d.*).tar\z/

    case Regex.named_captures(name_regex, name) do
      nil ->
        {:error, :not_valid}

      captures ->
        package = %__MODULE__{
          name: captures["package_name"],
          version: captures["version"]
        }

        {:ok, package}
    end
  end

  def load_from_tarball(tarball) do
    with {:ok, result} <- :hex_tarball.unpack(tarball, :memory),
         :ok <- validate_name(result.metadata),
         :ok <- validate_version(result.metadata) do
      package = %__MODULE__{
        name: result.metadata["name"] || result.metadata["app"],
        version: result.metadata["version"],
        release: build_release(result),
        tarball: tarball
      }

      {:ok, package}
    end
  end

  defp build_release(result) do
    %{
      version: Map.fetch!(result.metadata, "version"),
      inner_checksum: result.inner_checksum,
      outer_checksum: result.outer_checksum,
      dependencies: build_dependencies(result.metadata)
    }
  end

  defp build_dependencies(%{"requirements" => %{}} = metadata) do
    for {package, map} <- Map.fetch!(metadata, "requirements") do
      %{
        package: package,
        requirement: map["requirement"]
      }
      |> maybe_put(:app, map["app"])
      |> maybe_put(:optional, map["optional"])
      |> maybe_put(:repository, map["repository"])
    end
  end

  defp build_dependencies(metadata) do
    Logger.warn([inspect(__MODULE__), " loading package ", metadata["name"] || metadata["app"], " with missing requirements field"])
    []
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp validate_name(metadata) do
    if metadata["name"] || metadata["app"] =~ ~r/^[a-z]\w*$/ do
      :ok
    else
      {:error, :invalid_name}
    end
  end

  defp validate_version(metadata) do
    case Version.parse(metadata["version"]) do
      {:ok, _} -> :ok
      :error -> {:error, :invalid_version}
    end
  end
end
