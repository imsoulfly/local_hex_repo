defmodule LocalHex.Mirror.HexPm do
  @moduledoc """
  The `LocalHex.Mirror.HexPm` module is the interface towards the Hex.pm API. In addition
  to API calls it is able to to decode and encode the necessary registry files for the
  local repo configuration
  """
  require Logger

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
               ssl: ssl_opts_for_url(repository.options.upstream_url)
             ]
           }}
    }
  end

  defp ssl_opts_for_url(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host} when is_binary(host) and host != "" ->
        [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          depth: 3,
          server_name_indication: String.to_charlist(host),
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]

      _ ->
        []
    end
  end

  defp user_agent_fragment do
    {:ok, vsn} = :application.get_key(:local_hex, :vsn)
    "local_hex_repo/#{vsn}"
  end
end
