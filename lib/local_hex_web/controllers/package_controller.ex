defmodule LocalHexWeb.PackageController do
  use LocalHexWeb, :controller

  alias LocalHex.{Registry, Repository}

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      repo: Repository.load(repository_config())
    )
  end

  def show(conn, %{"name" => name}) do
    repository = Repository.load(repository_config())
    package = Registry.all_versions_of_package(repository.registry, name)

    render(
      conn,
      "show.html",
      package: package,
      repo: Repository.load(repository_config())
    )
  end
end
