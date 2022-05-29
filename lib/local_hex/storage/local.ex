defmodule LocalHex.Storage.Local do
  @moduledoc """
  Adapter module to provide local file system abilities

  In the config files (ex. config.exs) you can configure each repository individually by
  providing a `:store` field that contains a tuple with the details.
  ```
  config :local_hex,
    auth_token: "local_token",
    repositories: [
      main: [
        name: "local_hex_dev",
        store: {LocalHex.Storage.Local, root: "priv/repos/"},
        ...
      ]
  ```
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

    case File.read(path) do
      {:ok, contents} ->
        Logger.debug(inspect({__MODULE__, :read, path, :successful}))
        {:ok, contents}

      {:error, :enoent} ->
        Logger.debug(inspect({__MODULE__, :read, path, :not_found}))
        {:error, :not_found}

      other ->
        Logger.debug(inspect({__MODULE__, :read, path, :unknown}))
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
