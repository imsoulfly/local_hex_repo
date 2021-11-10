defmodule LocalHex.Registry do
  @moduledoc """
  Module meant for maintaining a registry of available packages of a repository.

  Current `Registry` is kept in a simple Map structure and looks like the following:

  ```
  %{
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
  ```
  """

  def add_package(registry, package) do
    Map.update(registry, package.name, [package.release], fn releases ->
      [package.release | releases]
      |> Enum.uniq_by(fn %{version: version} -> version end)
      |> Enum.sort(&(Version.compare(&1.version, &2.version) == :lt))
    end)
  end

  def all_versions_of_packages(registry) do
    registry
    |> Map.keys()
    |> Enum.map(&all_versions_of_package(registry, &1))
  end

  def all_versions_of_package(registry, package_name) do
    versions =
      registry[package_name]
      |> Enum.map(fn entry -> entry[:version] end)
      |> Enum.sort()

    %{
      name: package_name,
      internal: true,
      versions: versions
    }
  end

  def has_version?(registry, package_name, version) do
    registry[package_name]
    |> Enum.any?(fn release ->
      release.version == version
    end)
  end

  def revert_release(registry, package_name, version) do
    Map.update!(registry, package_name, fn releases ->
      Enum.reject(releases, &(&1.version == version))
    end)
  end

  def retire_package_release(registry, package_name, version, reason, message) do
    Map.update!(registry, package_name, fn releases ->
      for release <- releases do
        if release.version == version do
          retired = %{
            reason: retirement_reason(reason),
            message: message
          }

          Map.put(release, :retired, retired)
        else
          release
        end
      end
    end)
  end

  def unretire_package_release(registry, package_name, version) do
    Map.update!(registry, package_name, fn releases ->
      for release <- releases do
        if release.version == version do
          Map.delete(release, :retired)
        else
          release
        end
      end
    end)
  end

  defp retirement_reason("invalid"), do: :RETIRED_INVALID
  defp retirement_reason("security"), do: :RETIRED_SECURITY
  defp retirement_reason("deprecated"), do: :RETIRED_DEPRECATED
  defp retirement_reason("renamed"), do: :RETIRED_RENAMED
  defp retirement_reason(_), do: :RETIRED_OTHER
end
