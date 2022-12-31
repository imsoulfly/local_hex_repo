defmodule LocalHex.MixProject do
  use Mix.Project

  def project do
    [
      app: :local_hex,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LocalHex.Application, []},
      extra_applications: [:logger, :runtime_tools, :crypto, :inets, :ssl, :hex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bulma, "0.9.4"},
      {:dart_sass, "~> 0.5"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.3"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:floki, ">= 0.30.0", only: :test},
      {:hackney, "~> 1.18"},
      {:hex_core, "~> 0.8"},
      {:jason, "~> 1.3"},
      {:logger_file_backend, "~> 0.0.12", only: :test},
      {:phoenix, "~> 1.6.0"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_view, "~> 0.17"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:plug_cowboy, "~> 2.5"},
      {:sweet_xml, "~> 0.7"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},

      # dev libraries
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:phoenix_live_reload, "~> 1.3", only: :dev}
    ]
  end

  defp dialyzer do
    [
      # plt_add_deps: :app_tree,
      # plt_add_apps: [],
      # plt_ignore_apps: []
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      "assets.deploy": [
        "sass default --no-source-map --style=compressed",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
