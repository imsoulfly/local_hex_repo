# LocalHex

Make hosting Erlang and Elixir libraries in your local infrastructure easy.

As a company or out of any other scenario you might want/need the ability to host your own Elixir / Erlang libraries within your internal network. For example when company knowledge legally should not be exposed publicly on [Hex.pm](http://hex.pm).

This project was inspired by the [MiniRepo](https://github.com/wojtekmach/mini_repo) Github project by Wojtek Mach. I personally was missing a Web UI and the library documentations and started this project to add those things.


## Features

* Publishing packages / documentation
* Functionial HEX API to provide dependencies for your apps
* Local file storage
* Web UI listing all available libraries/version
* Web UI also renders the documentation for your Elixir libraries


## Planned Features

* More storage adapters (S3, Swift,...)
* Mirroring public Hex libraries
* Admin UI to configure several things like the mirroring
* Your suggestions


## Preparing production deployment

You can simply use this codebase and include it in your usual deployment process. Building an Elixir release or starting the app with `MIX_ENV=prod mix phx.server` in your environment should both work.

For all that to properly work some configuration needs to be activated in the `config/prod.exs` file:

```
config :local_hex,
  auth_token: "secret_production_token",
  repositories_path: "priv/repos/",
  repositories: [
    main: [
      name: "local_hex",
      store: :local,
      private_key: File.read!(Path.expand("../path/to/private_key.pem", __DIR__)),
      public_key: File.read!(Path.expand("../path/to/public_key.pem", __DIR__))
    ]
  ]
```

* __auth_token__: This token is a secret string of your choice to also be used later by the local or CI/CD environments to authenticate via the `Mix` tool. Suggestion: Best to be provided via ENV vars via your infrastructure to not have it included in your codebase.

* __repositories_path__: The folder where published packages of your libs are stored. In case you are using volumes for Docker instances it might be necessary to customize this for example.

* __repositories__: Currently only the a single `main` repository is possible to be configured.

* __name__: Name of the repository which also is used in the `hex.config` and `deps` configuration

* __store__: Currently it's only possible to choose `:local` to store packages. More adapters are planned like `S3` and other protocols.

* __private_key__: Private key generated via `ssh` or any other way. This is used to sign packages. Suggestion: It's best to be provided via your infrastructure and not to be included in your codebase.

* __public_key__: Public key material for you private key. This is used to validate published packages with the private key. Suggestion: It's best to be provided via your infrastructure and not to be included in your codebase.


## Publish packages

To publish a library to your `local_hex` app deployment you need to adapt the `mix.exs` of your library a bit. You might want to add different things as this just serves as an example.

```
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

```
mix hex.publish
```

## Use your locally hosted libraries

Be aware that the `Hex` repo needs to added in every local dev environment and especially also in the CI/CD system of your infrastructure.
It can look like the following but these commands are also accessible in the web frontend of this app as a setup guide.

```
wget -q https://local_hex.your_company.com/public_key
mix hex.repo add local_hex https://local_hex.your_company.com --public-key public_key
rm -f public_key
```

Using your locally hosted libraries in your application is quite simple by specifing the `repo` field in the deps config.

```
defp deps do
  [
     {:phoenix, "~> 1.6.0"},
     {:your_library, "~> 1.1.3", repo: :local_hex}
  ]
end
```


## Local setup in case you want to adapt or support this project

To start the local runtime:

```
mix deps.get
mix phx.server
```

This will add the development version of the local_hex repo to your local `hex` configuration:

```
wget -q http://localhost:4000/public_key
mix hex.repo add local_hex_dev http://localhost:4000 --public-key public_key
rm -f public_key
```

If you want to publish a library, you need to adapt the `mix.exs` file with some `hex` config:
```
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

```
mix hex.publish
```
