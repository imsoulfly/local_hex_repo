defmodule LocalHex.Registry do
  @moduledoc """
  Module meant for maintaining a registry of available packages of of a repository.

  Current the `Registry` is kept in a simple Map structure and looks like the follwing:

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
end
