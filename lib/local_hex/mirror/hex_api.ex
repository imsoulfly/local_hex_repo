defmodule LocalHex.Mirror.HexApi do
  @moduledoc false
  require Logger

  @callback fetch_hexpm_names(LocalHex.Repository.t()) :: {:ok, binary} | {:error, any}
  @callback fetch_hexpm_versions(LocalHex.Repository.t()) :: {:ok, binary} | {:error, any}
  @callback fetch_hexpm_package(LocalHex.Repository.t(), binary) :: {:ok, binary} | {:error, any}
  @callback fetch_hexpm_tarball(LocalHex.Repository.t(), binary, binary) ::
              {:ok, binary} | {:error, any}

  def fetch_hexpm_names(repository) do
    Logger.debug("#{inspect(impl())} fetch_hexpm_names #{inspect(repository)}")
    impl().fetch_hexpm_names(repository)
  end

  def fetch_hexpm_versions(repository) do
    Logger.debug("#{inspect(impl())} fetch_hexpm_versions")
    impl().fetch_hexpm_versions(repository)
  end

  def fetch_hexpm_package(repository, name) do
    Logger.debug("#{inspect(impl())} fetch_hexpm_package")
    impl().fetch_hexpm_package(repository, name)
  end

  def fetch_hexpm_tarball(repository, name, version) do
    Logger.debug("#{inspect(impl())} fetch_hexpm_tarball")
    impl().fetch_hexpm_tarball(repository, name, version)
  end

  defp impl do
    Application.get_env(:local_hex, :hex_api, LocalHex.Mirror.HexPm)
  end
end
