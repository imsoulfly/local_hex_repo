defmodule LocalHexWeb.Plugs.DocsStatic do
  @moduledoc """
  Serves extracted documentation under `/docs/*`.

  By default, docs are served from `priv/static/docs` inside the application.
  In containerized deployments this path is often read-only, so you can override
  the docs root with `LOCAL_HEX_DOCS_CACHE_DIR` to point at a writable volume.
  """

  @behaviour Plug

  @impl true
  def init(opts) do
    # IMPORTANT: `init/1` for plugs in an Endpoint is typically evaluated at compile-time.
    # Keep it side-effect free and read env vars at request time in `call/2`.
    opts
  end

  @impl true
  def call(conn, opts) do
    from =
      System.get_env("LOCAL_HEX_DOCS_CACHE_DIR") ||
        Keyword.get(opts, :default_from, {:local_hex, "priv/static/docs"})

    static_opts = Plug.Static.init(at: "/docs", from: from, gzip: false)
    Plug.Static.call(conn, static_opts)
  end
end
