defmodule LocalHexWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use LocalHexWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  # alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import LocalHexWeb.ConnCase

      alias LocalHexWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint LocalHexWeb.Endpoint
    end
  end

  setup _tags do
    # pid = Sandbox.start_owner!(LocalHex.Repo, shared: not tags[:async])
    on_exit(fn ->
      root_path()
      |> File.rm_rf()

      # Sandbox.stop_owner(pid)
    end)

    {:ok, conn: Phoenix.ConnTest.build_conn(), repository: repository_config()}
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
end
