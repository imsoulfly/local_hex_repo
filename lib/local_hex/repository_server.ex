defmodule LocalHex.RepositoryServer do
  @moduledoc """
  This module serves the purpose of streamlining all changes to repos through one central process.
  We are basically making use of how the process mailbox is handled step by stap and that way it prevents
  race conditions when multiple changes happen concurrently which in the worst case would lead to
  broken or overwritten repository states.
  """

  use GenServer

  alias LocalHex.Repository

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def publish(repository, tarball) do
    GenServer.call(__MODULE__, {:publish, repository, tarball})
  end

  def publish_docs(repository, name, version, tarball) do
    GenServer.call(__MODULE__, {:publish_docs, repository, name, version, tarball})
  end

  def revert(repository, package_name, version) do
    GenServer.call(__MODULE__, {:revert, repository, package_name, version})
  end

  def retire(repository, package_name, version, reason, message) do
    GenServer.call(__MODULE__, {:retire, repository, package_name, version, reason, message})
  end

  def unretire(repository, package_name, version) do
    GenServer.call(__MODULE__, {:unretire, repository, package_name, version})
  end

  def handle_call({:publish, repository, tarball}, _, server) do
    result = Repository.publish(repository, tarball)

    {:reply, result, server}
  end

  def handle_call({:publish_docs, repository, name, version, tarball}, _, server) do
    result = Repository.publish_docs(repository, name, version, tarball)

    {:reply, result, server}
  end

  def handle_call({:revert, repository, package_name, version}, _, server) do
    result = Repository.revert(repository, package_name, version)

    {:reply, result, server}
  end

  def handle_call({:retire, repository, package_name, version, reason, message}, _, server) do
    result = Repository.retire(repository, package_name, version, reason, message)

    {:reply, result, server}
  end

  def handle_call({:unretire, repository, package_name, version}, _, server) do
    result = Repository.unretire(repository, package_name, version)

    {:reply, result, server}
  end
end
