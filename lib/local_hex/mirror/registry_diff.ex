defmodule LocalHex.Mirror.RegistryDiff do
  @moduledoc """
  The `LocalHex.Mirror.Diff` module supports the sync module by providing a diff comparison
  between the origin repository (hex.pm) and the local repository
  """

  def compare(mirror, upstream) do
    mirror_packages = Map.keys(mirror)
    upstream_packages = Map.keys(upstream)
    created_packages = upstream_packages -- mirror_packages
    deleted_packages = mirror_packages -- upstream_packages

    releases =
      for name <- mirror_packages -- deleted_packages, into: %{} do
        mirror_versions = Enum.map(mirror[name], & &1.version)
        upstream_versions = upstream[name].versions

        mirror_retired =
          for release <- mirror[name], match?(%{retired: %{reason: _}}, release) do
            release.version
          end

        upstream_retired =
          for index <- upstream[name].retired do
            Enum.at(upstream_versions, index)
          end

        {name,
         %{
           created: sort_versions(upstream_versions -- mirror_versions),
           deleted: sort_versions(mirror_versions -- upstream_versions),
           retired: sort_versions(upstream_retired -- mirror_retired),
           unretired: sort_versions(mirror_retired -- upstream_retired)
         }}
      end

    releases =
      releases
      |> Enum.filter(fn {_name, map} ->
        map.created != [] or
          map.deleted != [] or
          map.retired != [] or
          map.unretired != []
      end)
      |> Enum.into(%{})

    %{
      packages: %{
        created: Enum.sort(created_packages),
        deleted: Enum.sort(deleted_packages)
      },
      releases: releases
    }
  end

  def deps_compare(updated, source) do
    updated_set = collect_dependencies(updated)
    source_set = collect_dependencies(source)

    MapSet.difference(updated_set, source_set)
    |> MapSet.to_list()
    |> case do
      [] ->
        {:ok, :equal}

      difference ->
        {:ok, difference}
    end
  end

  defp collect_dependencies(registry) do
    Enum.reduce(registry, MapSet.new(), fn {_, releases}, complete_set ->
      dependencies = collect_dependencies_of_releases(releases)

      MapSet.union(complete_set, dependencies)
    end)
  end

  defp collect_dependencies_of_releases(releases) do
    Enum.reduce(releases, MapSet.new(), fn release, complete_set ->
      dependencies =
        Enum.reduce(release.dependencies, MapSet.new(), fn dependency, dep_list ->
          MapSet.put(dep_list, dependency.package)
        end)

      MapSet.union(complete_set, dependencies)
    end)
  end

  defp sort_versions(list) do
    Enum.sort(list, &(Version.compare(&1, &2) == :lt))
  end
end
