# General application configuration
import Config

config :local_hex,
  ecto_repos: [LocalHex.Repo],
  storage: [
    root_path: "./priv/static/storage"
  ]

config :local_hex, LocalHexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RTqooXhIxmqE72o+hTZLTNgwDlWtEkgV08UPotLOvnjL81F6NPfbdnz3k7ysnTV0",
  render_errors: [view: LocalHexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LocalHex.PubSub,
  live_view: [signing_salt: "9DO+WBcQ"]

config :esbuild,
  version: "0.14.42",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :mime, :types, %{
  "application/vnd.hex+erlang" => ["hex"]
}

config :dart_sass,
  version: "1.52.1",
  default: [
    args: ~w(--load-path=../deps/bulma css:../priv/static/assets),
    cd: Path.expand("../assets", __DIR__)
  ]

if Mix.env() == :dev do
  config :mix_test_watch,
    tasks: [
      "test --failed",
      "coveralls.html",
      "credo --strict"
    ]
end

import_config "#{config_env()}.exs"
