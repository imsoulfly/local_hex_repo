defmodule ExampleLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :example_lib,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Example lib to locally test the local hex app",
      package: package(),
      hex: hex(),
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["XING-internal"],
      links: %{}
    ]
  end

  defp hex do
    [
      api_url: "http://localhost:4000/api",
      api_key: "api_key"
    ]
  end
end
