defmodule LocalHex.Storage do
  @moduledoc """
  Wrapper around File module for write, read and delete actions.

  For now only local!
  This will later serve as behavior to allow other storage methods in addtion
  like S3, FTP to name a few.
  """

  require Logger

  alias LocalHex.{Documentation, Package}

  def write_repository(repository, content) do
    write(repository, repository_file_path(repository), content)
  end

  def write_names(repository, content) do
    write(repository, names_path(), content)
  end

  def write_versions(repository, content) do
    write(repository, versions_path(), content)
  end

  def write_package(repository, name, content) do
    write(repository, package_path(name), content)
  end

  def write_package_tarball(repository, package) do
    write(repository, package_tarball_path(package), package.tarball)
  end

  def write_docs_tarball(repository, documentation) do
    write(repository, docs_tarball_path(documentation), documentation.tarball)
  end

  def write(repository, path, value) do
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :write, path}))

    File.mkdir_p!(Path.dirname(path))
    File.write(path, value)
  end

  def read_repository(repository) do
    read(repository, repository_file_path(repository))
  end

  def read_names(repository) do
    read(repository, names_path())
  end

  def read_versions(repository) do
    read(repository, versions_path())
  end

  def read_package(repository, name) do
    read(repository, package_path(name))
  end

  def read_package_tarball(repository, tarball) do
    read(repository, package_tarball_path(tarball))
  end

  def read_docs_tarball(repository, tarball) do
    read(repository, docs_tarball_path(tarball))
  end

  def read(repository, path) do
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :get, path}))

    case File.read(path) do
      {:ok, contents} ->
        {:ok, contents}

      {:error, :enoent} ->
        {:error, :not_found}

      other ->
        other
    end
  end

  def delete(repository, path) do
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :delete, path}))

    case File.rm(path) do
      :ok ->
        :ok

      {:error, :enoent} ->
        {:error, :not_found}

      other ->
        other
    end
  end

  defp repository_file_path(repository) do
    repository.name <> ".bin"
  end

  defp names_path do
    ["names"]
  end

  defp versions_path do
    ["versions"]
  end

  defp package_path(package_name) do
    ["packages", "#{package_name}"]
  end

  defp package_tarball_path(%Package{} = package) do
    ["tarballs", "#{package.name}-#{package.version}.tar"]
  end

  defp package_tarball_path(tarball) do
    ["tarballs", tarball]
  end

  defp docs_tarball_path(%Documentation{} = documentation) do
    ["docs", "#{documentation.name}-#{documentation.version}.tar"]
  end

  defp docs_tarball_path(tarball) do
    ["docs", tarball]
  end

  defp path(repository, path) do
    Path.join([root_path(), repository.name | List.wrap(path)])
  end

  defp root_path do
    path = Application.fetch_env!(:local_hex, :repositories_path)
    Path.join(Application.app_dir(:local_hex), path)
  end
end
