defmodule LocalHex.Mirror.HexPm do
  @moduledoc """
  The `LocalHex.Mirror.HexPm` module is the interface towards the Hex.pm API. In addition
  to API calls it is able to to decode and encode the necessary registry files for the
  local repo configuration
  """
  require Logger

  alias Hex.HTTP.SSL

  def fetch_hexpm_names(repository) do
    Logger.debug("#{inspect(__MODULE__)} fetching names")

    config = hex_config(repository)
    case :hex_http.request(config, :get, config.repo_url <> "/names", %{}, :undefined) do
      {:ok, {200, _, signed}} -> {:ok, signed}
      error -> error
    end
  end

  def fetch_hexpm_versions(repository) do
    Logger.debug("#{inspect(__MODULE__)} fetching versions")

    config = hex_config(repository)
    case :hex_http.request(config, :get, config.repo_url <> "/versions", %{}, :undefined) do
      {:ok, {200, _, signed}} -> {:ok, signed}
      error -> error
    end
  end

  def fetch_hexpm_package(repository, name) do
    Logger.debug("#{inspect(__MODULE__)} fetching package #{name}")

    config = hex_config(repository)
    case :hex_http.request(config, :get, config.repo_url <> "/packages/" <> name, %{}, :undefined) do
      {:ok, {200, _, signed}} -> {:ok, signed}
      error -> error
    end
  end

  def fetch_hexpm_tarball(repository, name, version) do
    Logger.debug("#{inspect(__MODULE__)} fetching tarball #{name}-#{version}.tar")

    config = hex_config(repository)
    case :hex_repo.get_tarball(config, name, version) do
      {:ok, {200, _, tarball}} -> {:ok, tarball}
      error -> error
    end
  end

  defp hex_config(repository) do
    %{
      :hex_core.default_config()
      | repo_name: repository.options.upstream_name,
        repo_url: repository.options.upstream_url,
        repo_public_key: repository.options.upstream_public_key,
        http_user_agent_fragment: user_agent_fragment(),
        http_adapter:
          {:hex_http_httpc,
           %{
             profile: :default,
             http_options: [
               ssl: SSL.ssl_opts(repository.options.upstream_url)
             ]
           }}
    }
  end

  defp user_agent_fragment do
    {:ok, vsn} = :application.get_key(:local_hex, :vsn)
    "local_hex_repo/#{vsn}"
  end
end
