# ExampleLib

This is a test library for the local hex app to be used in a local dev environment.

To release a version simply do the following while the local local hex app is running.

```
mix deps.get
mix hex.publish
```

If you want to release some additional versions for this library simply change the version in the `mix.exs` file and publish again.

```
def project do
  [
    app: :example_lib,
    version: "0.1.1", # <<<< Change this here
    elixir: "~> 1.9",
    start_permanent: Mix.env() == :prod,
    deps: deps(),
    description: "Example lib to locally test the local hex app",
    package: package(),
    hex: hex(),
  ]
end
```


