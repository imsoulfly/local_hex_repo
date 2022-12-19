defmodule LocalHexWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use LocalHexWeb, :controller
      use LocalHexWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: LocalHexWeb

      import Plug.Conn
      alias LocalHex.Repository
      alias LocalHexWeb.Router.Helpers, as: Routes

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

  def view do
    quote do
      use Phoenix.View,
        root: "lib/local_hex_web/templates",
        namespace: LocalHexWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1, action_name: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LocalHexWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

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

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers
      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      alias LocalHexWeb.Router.Helpers, as: Routes

      def maybe_is_active_class(%{package: %{name: name}}, name), do: "is-active"
      def maybe_is_active_class(_, _), do: ""
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
