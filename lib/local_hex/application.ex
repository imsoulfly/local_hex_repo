defmodule LocalHex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    children =
      optional_mirror() ++
        [
          LocalHex.RepositoryServer,
          {Task.Supervisor, name: LocalHex.TaskSupervisor},
          LocalHexWeb.Telemetry,
          {Phoenix.PubSub, name: LocalHex.PubSub},
          LocalHexWeb.Endpoint
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LocalHex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LocalHexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp optional_mirror do
    repositories =
      Application.get_all_env(:local_hex)
      |> Keyword.fetch!(:repositories)

    case Enum.find(repositories, fn {type, _} -> type == :mirror end) do
      nil ->
        Logger.info("No mirror server configured")
        []

      {_type, options} ->
        Logger.info("Mirror server config found and being started")
        repo = LocalHex.Repository.init(options)
        [{LocalHex.Mirror.Server, repo}]
    end
  end
end
