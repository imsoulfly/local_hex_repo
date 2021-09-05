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
    end)
    :ok
  end

  def path(path) do
    Path.join([root_path() | List.wrap(path)])
  end

  def root_path do
    Application.fetch_env!(:local_hex, :storage)[:root_path]
  end
end
