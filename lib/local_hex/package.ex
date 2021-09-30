defmodule LocalHex.Package do
  @moduledoc false

  defstruct [:name, :version, :release, :tarball]

  def load_from_tarball(tarball) do
    with {:ok, result} <- :hex_tarball.unpack(tarball, :memory),
         :ok <- validate_name(result.metadata),
         :ok <- validate_version(result.metadata) do

      package = %__MODULE__{
        name: result.metadata["name"],
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

  defp build_dependencies(metadata) do
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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp validate_name(metadata) do
    if metadata["name"] =~ ~r/^[a-z]\w*$/ do
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
