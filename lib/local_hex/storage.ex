defmodule LocalHex.Storage do
  @moduledoc """
  Wrapper around File module for write, read and delete actions.

  For now only local!
  This will later serve as behavior to allow other storage methods in addtion
  like S3, FTP to name a few.
  """

  require Logger

  def write(path, value) do
    path = path(path)
    Logger.debug(inspect({__MODULE__, :put, path}))
    File.mkdir_p!(Path.dirname(path))
    File.write(path, value)
  end

  def read(path) do
    path = path(path)
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

  def delete(path) do
    path = path(path)
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

  defp path(path) do
    Path.join([root_path() | List.wrap(path)])
  end

  defp root_path do
    Application.fetch_env!(:local_hex, :storage)[:root_path]
  end
end
