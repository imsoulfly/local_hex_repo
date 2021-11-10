defmodule LocalHexWeb.HexErlangParser do
  @moduledoc """
  Module implementing the Plug.Parser behaviour sepcification to identfiy
  and handle `vnd.hex+erlang` content type

  Apache OS notice:
  The original source was taken from here:
  https://github.com/wojtekmach/mini_repo/blob/master/lib/mini_repo/hex_erlang_parser.ex
  """

  @behaviour Plug.Parsers

  @impl true
  def init(options) do
    options
  end

  @impl true
  def parse(%Plug.Conn{} = conn, "application", "vnd.hex+erlang", _headers, opts) do
    conn
    |> Plug.Conn.read_body(opts)
    |> decode()
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end

  defp decode({:more, _, conn}) do
    {:error, :too_large, conn}
  end

  defp decode({:error, :timeout}) do
    raise Plug.TimeoutError
  end

  defp decode({:error, _}) do
    raise Plug.BadRequestError
  end

  defp decode({:ok, "", conn}) do
    {:ok, %{}, conn}
  end

  defp decode({:ok, body, conn}) do
    terms = Plug.Crypto.non_executable_binary_to_term(body, [:safe])
    {:ok, terms, conn}
  rescue
    ArgumentError ->
      reraise Plug.BadRequestError, message: "bad terms"
  end
end
