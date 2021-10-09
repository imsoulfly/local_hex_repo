defmodule LocalHex.Documentation do
  @moduledoc false

  defstruct [:name, :version, :tarball]

  def load(name, version, tarball) do
    with {:ok, _result} <- :erl_tar.extract({:binary, tarball}, [:compressed, :memory]),
         :ok <- validate_name(name),
         :ok <- validate_version(version) do
      documentation = %__MODULE__{
        name: name,
        version: version,
        tarball: tarball
      }

      {:ok, documentation}
    else
      _ ->
        {:error, :invalid}
    end
  end

  defp validate_name(name) do
    if name =~ ~r/^[a-z]\w*$/ do
      :ok
    else
      {:error, :invalid_name}
    end
  end

  defp validate_version(version) do
    case Version.parse(version) do
      {:ok, _} ->
        :ok

      :error ->
        {:error, :invalid_version}
    end
  end
end
