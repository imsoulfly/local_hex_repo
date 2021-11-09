defmodule LocalHex.StorageCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      alias LocalHex.Storage

      import LocalHex.StorageCase
    end
  end

  setup _tags do
    on_exit(fn ->
      root_path()
      |> File.rm_rf()

      docs_root_path(repository_config())
      |> File.rm_rf()
    end)

    :ok
  end

  def repository_config do
    Application.fetch_env!(:local_hex, :repositories)
    |> Keyword.fetch!(:main)
    |> LocalHex.Repository.init()
  end

  def path(repository, path) do
    Path.join([root_path(), repository.name | List.wrap(path)])
  end

  def root_path do
    path = Application.fetch_env!(:local_hex, :repositories_path)
    Path.join(Application.app_dir(:local_hex), path)
  end

  def docs_root_path(repository) do
    Path.join([
      Application.app_dir(:local_hex),
      "priv",
      "static",
      "docs",
      repository.name
    ])
  end
end
