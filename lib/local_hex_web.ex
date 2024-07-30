defmodule LocalHexWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use LocalHexWeb, :controller
      use LocalHexWeb, :html

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(docs assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: LocalHexWeb.Layouts]

      import Plug.Conn

      alias LocalHex.Repository

      unquote(verified_routes())

      defp repository_config do
        Application.fetch_env!(:local_hex, :repositories)
        |> Keyword.fetch!(:main)
        |> Repository.init()
      end

      defp repository_mirror_config do
        Application.fetch_env!(:local_hex, :repositories)
        |> Keyword.get(:mirror)
        |> Repository.init()
      end
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LocalHexWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1, action_name: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      import LocalHexWeb.CoreComponents

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers
      import Phoenix.Component

      alias LocalHexWeb.Router.Helpers, as: Routes

      # Routes generation with the ~p sigil
      unquote(verified_routes())

      def maybe_is_active_class(%{package: %{name: name}}, name), do: "is-active"
      def maybe_is_active_class(_, _), do: ""
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: LocalHexWeb.Endpoint,
        router: LocalHexWeb.Router,
        statics: LocalHexWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
