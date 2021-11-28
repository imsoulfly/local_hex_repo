defmodule LocalHex.Storage.Local do
  @moduledoc """
  Adapter module to provide local file system abilities
  """

  @behaviour LocalHex.Storage

  require Logger

  @impl true
  def write(repository, path, value) do
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :write, path}))

    File.mkdir_p!(Path.dirname(path))
    File.write(path, value)
  end

  @impl true
  def read(repository, path) do
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :read, path}))

    case File.read(path) do
      {:ok, contents} ->
        Logger.debug(inspect({__MODULE__, :read, :successful}))
        {:ok, contents}

      {:error, :enoent} ->
        Logger.debug(inspect({__MODULE__, :read, :not_found}))
        {:error, :not_found}

      other ->
        other
    end
  end

  @impl true
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

  defp path(repository, path) do
    Path.join([root_path(repository.store), repository.name | List.wrap(path)])
  end

  defp root_path({_module, root: path}) do
    Path.join(Application.app_dir(:local_hex), path)
  end
end