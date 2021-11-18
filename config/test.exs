import Config

config :local_hex,
  storage: [
    root_path: "priv/static/test_storage"
  ],
  auth_token: "test_token",
  repositories: [
    main: [
      name: "test",
      store: {LocalHex.Storage.Local, root: "priv/test_repos/"},
      private_key: File.read!(Path.expand("../test/fixtures/test_private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../test/fixtures/test_public_key.pem", __DIR__))
    ]
  ]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :local_hex, LocalHex.Repo,
  username: "root",
  password: "",
  database: "local_hex_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :local_hex, LocalHexWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  url: [host: "localhost", scheme: "http", port: 4002],
  server: true

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [{LoggerFileBackend, :file_log}]

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :file_log,
  path: "./log/test.log",
  level: :debug

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
