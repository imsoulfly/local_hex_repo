defmodule LocalHexWeb.Plugs.AuthTokenCheck do
  @moduledoc """
  The Hex API expects for each request to provide a valid authorization token in the `authorization` headers
  that needs to match the configuration of the current system.

  If validation fails the plugs will halt the request immediately and return a `401` response.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if String.starts_with?(conn.request_path, "/api") do
      validate(conn, get_req_header(conn, "authorization"))
    else
      conn
    end
  end

  defp validate(conn, [token]) do
    if Plug.Crypto.secure_compare(token, Application.fetch_env!(:local_hex, :auth_token)) do
      conn
    else
      unauthorized(conn)
    end
  end

  defp validate(conn, _), do: unauthorized(conn)

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/vnd.hex+erlang")
    |> send_resp(401, :erlang.term_to_binary("unauthorized"))
    |> halt()
  end
end
