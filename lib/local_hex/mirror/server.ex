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
    Process.send_after(self(), :sync, 1000)

    {:ok, mirror}
  end

  def ensure_package(mirror, name) do
    GenServer.call(mirror, {:ensure_package, name}, :infinity)
  end

  def handle_info(:sync, mirror) do
    mirror = Repository.load(mirror)

    case Sync.sync(mirror) do
      {:ok, %Repository{} = new_mirror} ->
        schedule_sync(new_mirror)
        {:noreply, new_mirror}

      _ ->
        schedule_sync(mirror)
        {:noreply, mirror}
    end
  end

  def handle_call({:ensure_package, name}, _from, mirror) do
    mirror = Repository.load(mirror)

    case Sync.sync(mirror, name) do
      {:ok, %Repository{} = new_mirror} ->
        schedule_sync(new_mirror)
        {:reply, :ok, new_mirror}

      _ ->
        schedule_sync(mirror)
        {:reply, :ok, mirror}
    end
  end

  def handle_call(_msg, _from, mirror) do
    {:reply, :ok, mirror}
  end

  defp schedule_sync(mirror) do
    Process.send_after(self(), :sync, mirror.options.sync_interval)
  end
end
