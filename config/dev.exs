import Config

config :ex_aws, :s3,
  access_key_id: "123456789",
  secret_access_key: "123456789",
  scheme: "http://",
  host: "localhost",
  port: 9000,
  region: "local"

storage_config = {LocalHex.Storage.Local, root: "priv/repos/"}
# storage_config =
#   {LocalHex.Storage.S3,
#    bucket: "localhex",
#    options: [
#      region: "local"
#    ]}

config :local_hex,
  auth_token: "local_token",
  repositories: [
    main: [
      name: "local_hex_dev",
      store: storage_config,
      private_key: File.read!(Path.expand("../test/fixtures/test_private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../test/fixtures/test_public_key.pem", __DIR__))
    ],
    mirror: [
      name: "local_hex_dev_mirror",
      store: storage_config,
      private_key: File.read!(Path.expand("../test/fixtures/test_private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../test/fixtures/test_public_key.pem", __DIR__)),
      options: %{
        # sync_interval: 5 * 60 * 1000,
        sync_interval: 100 * 1000,
        sync_opts: [max_concurrency: 5, timeout: 60000],
        sync_only: ~w(jason),

        # Source: https://hex.pm/docs/public_keys
        upstream_name: "hexpm",
        upstream_url: "https://repo.hex.pm",
        upstream_public_key: """
        -----BEGIN PUBLIC KEY-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApqREcFDt5vV21JVe2QNB
        Edvzk6w36aNFhVGWN5toNJRjRJ6m4hIuG4KaXtDWVLjnvct6MYMfqhC79HAGwyF+
        IqR6Q6a5bbFSsImgBJwz1oadoVKD6ZNetAuCIK84cjMrEFRkELtEIPNHblCzUkkM
        3rS9+DPlnfG8hBvGi6tvQIuZmXGCxF/73hU0/MyGhbmEjIKRtG6b0sJYKelRLTPW
        XgK7s5pESgiwf2YC/2MGDXjAJfpfCd0RpLdvd4eRiXtVlE9qO9bND94E7PgQ/xqZ
        J1i2xWFndWa6nfFnRxZmCStCOZWYYPlaxr+FZceFbpMwzTNs4g3d4tLNUcbKAIH4
        0wIDAQAB
        -----END PUBLIC KEY-----
        """
      }
    ]
  ]

config :local_hex, LocalHexWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    sass: {
      DartSass,
      :install_and_run,
      [:default, ~w(--embed-source-map --source-map-urls=absolute --watch)]
    }
  ]

config :local_hex, LocalHexWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/local_hex_web/(live|views)/.*(ex)$",
      ~r"lib/local_hex_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000,
  region: "europe"

config :ex_aws,
  access_key_id: "123456789",
  secret_access_key: "123456789",
  json_codec: Jason
