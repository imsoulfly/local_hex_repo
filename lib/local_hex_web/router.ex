defmodule LocalHexWeb.Router do
  use LocalHexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LocalHexWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json", "hex"]
    plug LocalHexWeb.Plugs.AuthTokenCheck

    plug Plug.Parsers,
      parsers: [LocalHexWeb.HexErlangParser],
      pass: ["*/*"]
  end

  scope "/", LocalHexWeb do
    pipe_through :browser

    get "/", PackageController, :index
    get "/package/:name", PackageController, :show

    get "/names", StorageController, :names
    get "/versions", StorageController, :versions
    get "/docs/:tarball", StorageController, :docs_tarball
    get "/packages/:name", StorageController, :package
    get "/tarballs/:tarball", StorageController, :tarball
    get "/public_key", StorageController, :public_key

    get "/documentation/:name/:version", DocumentationController, :show
  end

  scope "/api", LocalHexWeb.API do
    pipe_through :api

    post "/publish", PackageController, :publish

    scope "/packages/:name/releases/:version" do
      delete "/", PackageController, :revert
      post "/retire", PackageController, :retire
      delete "/retire", PackageController, :unretire

      post "/docs", PackageController, :publish_docs
    end

    # Reminder to add account authentication as well if needed later
    # get "/users/me", ErrorController, :not_found
  end
end
