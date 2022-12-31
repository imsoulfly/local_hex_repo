defmodule LocalHex.Mirror.Server do
  @moduledoc """
  The `Mirror.Server` module provides a GenServer implementation that regularly triggers
  synchronisation tasks to keep the local repository in sync with the official Hex.pm repository.
  It therefor utilises the `Mirror.Sync` module which provides the logic for the synchronisation.
  """

  use GenServer

  require Logger

  alias LocalHex.Mirror.Sync
  alias LocalHex.Repository

  # @default_sync_opts [ordered: false]

  def start_link(mirror) do
    GenServer.start_link(__MODULE__, mirror, name: __MODULE__)
  end

  def init(mirror) do
    # Initiate sync loop interval
    schedule_sync(mirror, 1000)

    {:ok, new_state(mirror)}
  end

  def ensure_package(mirror, name) do
    GenServer.call(mirror, {:ensure_package, name}, :infinity)
  end

  def handle_info(:sync, state) do
    mirror = Repository.load(state.mirror)
    new_state = process_sync(mirror, state.deps)

    {:noreply, new_state}
  end

  def handle_call({:ensure_package, name}, _from, state) do
    mirror = Repository.load(state.mirror)
    new_state = process_sync(mirror, [name])

    {:reply, :ok, new_state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  defp process_sync(mirror, names) do
    case Sync.sync(mirror, names) do
      {:ok, %Repository{} = new_mirror} ->
        schedule_sync(new_mirror)
        new_state(new_mirror)

      {:new_deps, dep_list, %Repository{} = new_mirror} ->
        schedule_sync(new_mirror, 1_000)
        new_state(new_mirror, dep_list)

      _ ->
        schedule_sync(mirror)
        new_state(mirror)
    end
  end

  defp new_state(mirror, deps \\ []) do
    %{
      mirror: mirror,
      deps: deps
    }
  end

  defp schedule_sync(mirror, interval \\ nil) do
    Process.send_after(self(), :sync, interval || mirror.options.sync_interval)
  end
end
