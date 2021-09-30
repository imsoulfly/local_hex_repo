# General application configuration
import Config

config :local_hex,
  ecto_repos: [LocalHex.Repo],
  storage: [
    root_path: "./priv/static/storage"
  ],
  auth_token: "local_token",
  repositories_path: "priv/repos/",
  repositories: [
    main: [
      name: "main",
      store: :local,
      private_key: File.read!(Path.expand("../test/fixtures/test_private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../test/fixtures/test_public_key.pem", __DIR__))
    ]
  ]

config :local_hex, LocalHexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RTqooXhIxmqE72o+hTZLTNgwDlWtEkgV08UPotLOvnjL81F6NPfbdnz3k7ysnTV0",
  render_errors: [view: LocalHexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LocalHex.PubSub,
  live_view: [signing_salt: "9DO+WBcQ"]

config :local_hex, LocalHex.Mailer, adapter: Swoosh.Adapters.Local

config :swoosh, :api_client, false

config :esbuild,
  version: "0.12.18",
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

if Mix.env() == :dev do
  config :mix_test_watch,
    tasks: [
      "test --failed",
      "coveralls.html",
      "credo --strict"
    ]
end

import_config "#{config_env()}.exs"
