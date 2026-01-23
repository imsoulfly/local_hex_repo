# Local Hex Repository

Hosting Elixir libraries on your own in your own server infrastructure or in your local dev environment.

As a company or out of any other scenario you might want/need the ability to host your own Elixir / Erlang libraries within your internal network. For example when company knowledge legally should not be exposed publicly on [Hex.pm](http://hex.pm).

This project was inspired by the [MiniRepo](https://github.com/wojtekmach/mini_repo) Github project by Wojtek Mach. I personally was missing a Web UI and the library documentations and started this project to add those things.

## Features

* Hosting your private Elixir libraries (also Erlang libraries)
* Publishing packages and their documentation
* Mirroring public Hex.pm libraries
* Functionial HEX API to provide your private libraries for your apps
* Various storage adapter for local filesystem or S3
* Web UI listing all available libraries/version
* Web UI also renders the documentation for your Elixir libraries
* Simple phoenix app which is simple to run or deploy

## Planned Features

* More storage adapters (AWS.KMS, Swift, ...)
* Mirroring public Hex libraries incl. their dependency trees
* Admin UI to configure several things like the mirroring
* Your suggestions

## Preparing production deployment

LocalHex can be deployed as a normal Phoenix app (`mix phx.server`), as an OTP release (`mix release`), or via Docker.

In production (`MIX_ENV=prod`) the application is configured at runtime from environment variables (see `config/runtime.exs`).
This keeps secrets out of git and works well for containers / Kubernetes.

### Docker (recommended)

A `Dockerfile` and `docker-compose.yml` are included.

```bash
cp env.example .env
# edit .env and set at least:
# - SECRET_KEY_BASE
# - LOCAL_HEX_AUTH_TOKEN
docker compose up --build
```

Notes:

* The compose file mounts `./priv/repos` and `./priv/static/storage` into the container for persistence.
* The compose file mounts the test keys from `./test/fixtures/*.pem` for convenience. Do **not** use those keys in production.
* To generate `SECRET_KEY_BASE`: `openssl rand -base64 48`
* CI builds/pushes a container image to GHCR as `ghcr.io/<repo_owner>/local_hex_repo:<tag>` when git tags are pushed.

### Production configuration (env vars)

Required:

* `SECRET_KEY_BASE` (or `SECRET_KEY_BASE_PATH` pointing to a file containing the secret)
* `LOCAL_HEX_AUTH_TOKEN` (or `LOCAL_HEX_AUTH_TOKEN_PATH` pointing to a file containing the token)
* Signing keys (provide either PEM *or* file paths):
  * `LOCAL_HEX_PRIVATE_KEY_PEM` or `LOCAL_HEX_PRIVATE_KEY_PATH`
  * `LOCAL_HEX_PUBLIC_KEY_PEM` or `LOCAL_HEX_PUBLIC_KEY_PATH`

Common:

* `LOCAL_HEX_REPO_NAME` (default: `local_hex`)
* `PORT` (default: `4000`)
* `PHX_HOST` (default: `localhost`)
* `LOG_LEVEL` (ex. `debug|info|warning|error`, default: `info`)
* `PHX_STATIC_GZIP` (`true` to serve pre-compressed assets from `priv/static` in prod)

Storage:

* Local filesystem (default):
  * `LOCAL_HEX_STORE=local`
  * `LOCAL_HEX_REPO_ROOT` (default: `/data/repos`)
* S3:
  * `LOCAL_HEX_STORE=s3`
  * `LOCAL_HEX_S3_BUCKET` (required)
  * `AWS_REGION` / `AWS_DEFAULT_REGION` (default: `us-east-1`)
  * Optional IRSA / web identity: `AWS_ROLE_ARN` + `AWS_WEB_IDENTITY_TOKEN_FILE`


## Adding setup for a Hex.pm mirror

To configure the mirror ability add the following repository configuration for the `:mirror` to your configuration list of repositories.

In production you can also enable the mirror via environment variables:

* `LOCAL_HEX_MIRROR_ENABLED=true`
* `LOCAL_HEX_MIRROR_UPSTREAM_PUBLIC_KEY_PEM` (or `LOCAL_HEX_MIRROR_UPSTREAM_PUBLIC_KEY_PATH`)
* Optional overrides: `LOCAL_HEX_MIRROR_REPO_NAME`, `LOCAL_HEX_MIRROR_SYNC_INTERVAL_MS`,
  `LOCAL_HEX_MIRROR_UPSTREAM_NAME`, `LOCAL_HEX_MIRROR_UPSTREAM_URL`

```elixir
config :local_hex,
  repositories: [
    ...,
    mirror: [
      name: "local_hex_dev_mirror", # Any name you like
      store: {LocalHex.Storage.Local, root: {:local_hex, "priv/repos/"}},
      private_key: File.read!(Path.expand("../test/fixtures/test_private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../test/fixtures/test_public_key.pem", __DIR__)),
      options: %{
        sync_interval: 60 * 60 * 1000, # every hour
        sync_opts: [max_concurrency: 5, timeout: 20000],
        sync_on_demand: true,
        sync_only: ~w(jason, phoenix, ...), # Any library you like

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
```

* __name__: Name of the repository which also is used in the `hex.config` and `deps` configuration

* __store__: Currently it's only possible to choose `LocalHex.Storage.(Local | S3)` to store packages. In case more is need it is pretty easy to write another adapter. Also see the adapter modules for their configuration.

* __private_key__: Private key generated via `ssh` or any other way. This is used to sign packages. Suggestion: It's best to be provided via your infrastructure and not to be included in your codebase.

* __public_key__: Public key material for you private key. This is used to validate published packages with the private key. Suggestion: It's best to be provided via your infrastructure and not to be included in your codebase.

* __sync_interval__: The interval in milliseconds to wait between rechecks if something new has to be mirrored

* __sync_opts__: Currently only timeout or concurrency controls for the sync, more documentation and options will follow

* __sync_on_demand__: Dependencies when requested but missing will be tried to synced from upstream

* __sync_only__: The selection of dependencies to mirror from upstream

* __upstream_name__: Default name of Hex.pm, could be changed to some third party package storage

* __upstream_url__: Default url of Hex.pm, could be changed to some third party package storage url

* __upstream_public_key__: Default public key of Hex.pm, could be changed to some third party package storage public key

## Additional storage adapters

Note: The configuration snippets below are for configuring storage via `config/*.exs` (development/tests or custom deployments).
For `MIX_ENV=prod`, prefer the environment variables described above.

### Local

The `LocalHex.Storage.Local` adapter writes data directly to the local filesystem.

In the config files (ex. config.exs) you can configure each repository individually by
providing a `:store` field that contains a tuple with the details.

In the second element in we have keyword list containing a `:root` field defining the preferred location of your repo

```elixir
config :local_hex,
  auth_token: "secret_production_token",
  repositories: [
    main: [
      name: "local_hex",
      store: {LocalHex.Storage.Local, root: {:local_hex, "priv/repos/"}},
      private_key: File.read!(Path.expand("../path/to/private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../path/to/public_key.pem", __DIR__))
    ]
  ]
```

### S3 with ExAWS

The `LocalHex.Storage.S3` adapter writes data directly to any S3 compatible storage system (AWS, S3, MinIO, etc.).

In the config files (ex. config.exs) you can configure each repository individually by
providing a `:store` field that contains a tuple with the details.

In the second element in we have keyword list containing a `:bucket` and `:options` field defining the preferred bucket plus additional
options to be used when communicating with the storage (see ExAWS config).

Additionally you need to configure `ex_aws` as well to be able to connect properly to a server and bucket
of your choice. More details you find here [ExAWS](https://github.com/ex-aws/ex_aws/blob/master/lib/ex_aws/config.ex)

```elixir
config :ex_aws, :s3,
  access_key_id: "123456789",
  secret_access_key: "123456789",
  scheme: "http://",
  host: "localhost",
  port: 9000,
  region: "local"

storage_config =
  {LocalHex.Storage.S3,
   bucket: "localhex",
   options: [
     region: "local"
   ]}

config :local_hex,
  auth_token: "local_token",
  repositories: [
    main: [
      name: "local_hex_dev",
      store: storage_config,
      ...
    ]
  ]

```

## Publish packages

To publish a library to your `local_hex` app deployment you need to adapt the `mix.exs` of your library a bit. You might want to add different things as this just serves as an example.

```elixir
defmodule ExampleLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :example_lib,
      version: "0.1.0",
      ...
      package: package(),
      hex: hex(),
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{}
    ]
  end

  defp hex do
    [
      api_url: "https://local_hex.your_company.com/api",
      api_key: "secret_production_token"
    ]
  end
end
```

Now the library can be publish via the following command:

```bash
mix hex.publish
```

## Use your locally hosted libraries

Be aware that the `Hex` repo needs to added in every local dev environment and especially also in the CI/CD system of your infrastructure. This is case for both the repository of your own dependencies but also for the the mirror repository in case you have set it up.

It can look like the following but these commands are also accessible in the web frontend of this app as a setup guide. In the example the repository is named `local_hex` in its configuration.

```bash
wget -q https://local_hex.your_company.com/public_key
mix hex.repo add local_hex https://local_hex.your_company.com --public-key public_key
rm -f public_key
```

Using your locally hosted libraries in your application is quite simple by specifing the `repo` field in the deps config.

```elixir
defp deps do
  [
     {:phoenix, "~> 1.6.0"},
     {:your_library, "~> 1.1.3", repo: :local_hex}
  ]
end
```

## Local setup in case you want to adapt or support this project

To start the local runtime:

```bash
mix deps.get
mix phx.server
```

Alternatively, you can run it locally via Docker:

```bash
cp env.example .env
docker compose up --build
```

This will add the development version of the local_hex repo to your local `hex` configuration:

```bash
wget -q http://localhost:4000/public_key
mix hex.repo add local_hex_dev http://localhost:4000 --public-key public_key
rm -f public_key
```

If you want to publish a library, you need to adapt the `mix.exs` file with some `hex` config:

```elixir
defmodule ExampleLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :example_lib,
      version: "0.1.0",
      ...
      package: package(),
      hex: hex(),
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{}
    ]
  end

  defp hex do
    [
      api_url: "http://localhost:4000/api",
      api_key: "local_token"
    ]
  end
end
```

Now the library can be publish via the following command:

```bash
mix hex.publish
```
