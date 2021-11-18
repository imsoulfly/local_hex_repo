import Config

# Define the production config for your deployed application here.
# Be aware to keep the `auth_token` and especially the `private_key` in safe place
# and outside the repository like on the server as files, volumes, ENV vars
#
# config :local_hex,
#   auth_token: "production_token",
#   repositories: [
#     main: [
#       name: "local_hex",
#       store: {LocalHex.Storage.Local, root: "priv/repos/"},
#       private_key: File.read!(Path.expand("../path/to/private_key.pem", __DIR__)),
#       public_key: File.read!(Path.expand("../path/to/public_key.pem", __DIR__))
#     ]
#   ]

config :local_hex, LocalHexWeb.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info
