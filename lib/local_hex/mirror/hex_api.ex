defmodule LocalHex.Mirror.HexApi do
  @moduledoc false

  @callback fetch_hexpm_names(LocalHex.Repository.t()) :: {:ok, binary} | {:error, any}
  @callback fetch_hexpm_versions(LocalHex.Repository.t()) :: {:ok, binary} | {:error, any}
  @callback fetch_hexpm_package(LocalHex.Repository.t(), binary) :: {:ok, binary} | {:error, any}
  @callback fetch_hexpm_tarball(LocalHex.Repository.t(), binary, binary) ::
              {:ok, binary} | {:error, any}

  def fetch_hexpm_names(repository), do: impl().fetch_hexpm_names(repository)
  def fetch_hexpm_versions(repository), do: impl().fetch_hexpm_versions(repository)
  def fetch_hexpm_package(repository, name), do: impl().fetch_hexpm_package(repository, name)

  def fetch_hexpm_tarball(repository, name, version),
    do: impl().fetch_hexpm_tarball(repository, name, version)

  defp impl do
    Application.get_env(:local_hex, :hex_api, LocalHex.Mirror.HexPm)
  end
end
