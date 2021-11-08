defmodule LocalHexWeb.PackageController do
  use LocalHexWeb, :controller

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      repo: LocalHex.Repository.load(repository_config())
    )
  end

  def show(conn, %{"name" => name}) do
    repository = LocalHex.Repository.load(repository_config())
    package = LocalHex.Registry.all_versions_of_package(repository.registry, name)

    render(
      conn,
      "show.html",
      package: package,
      repo: LocalHex.Repository.load(repository_config())
    )
  end
end
