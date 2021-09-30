defmodule LocalHex.Storage do
  @moduledoc """
  Wrapper around File module for write, read and delete actions.

  For now only local!
  This will later serve as behavior to allow other storage methods in addtion
  like S3, FTP to name a few.
  """

  require Logger

  alias LocalHex.Package

  def write(repository, %Package{tarball: tarball} = package) when not is_nil(tarball) do
    write(repository, tarball_path(package), tarball)
  end

  def write(repository, path, value) do
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :write, path}))

    File.mkdir_p!(Path.dirname(path))
    File.write(path, value)
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

  defp tarball_path(package) do
    ["tarballs", "#{package.name}-#{package.version}.tar"]
  end

  defp path(repository, path) do
    Path.join([root_path(), repository.name | List.wrap(path)])
  end

  defp root_path do
    path = Application.fetch_env!(:local_hex, :repositories_path)
    Path.join(Application.app_dir(:local_hex), path)
  end
end
