defmodule LocalHexWeb.Plugs.AuthTokenCheckTest do
  use LocalHexWeb.ConnCase

  alias LocalHexWeb.Plugs.AuthTokenCheck

  test "init just returns opts" do
    opts = [test: :foo]
    result = AuthTokenCheck.init(opts)

    assert ^opts = result
  end

  test "call successful with not not matching endpoint" do
    conn =
      build_conn(:get, "/another_endpoint")
      |> Plug.Conn.put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
      |> AuthTokenCheck.call([])

    assert conn.halted == false
  end

  test "call successful with correct authorization header" do
    conn =
      build_conn(:get, "/api/endpoint")
      |> Plug.Conn.put_req_header("authorization", Application.fetch_env!(:local_hex, :auth_token))
      |> AuthTokenCheck.call([])

    assert conn.halted == false
  end

  test "call unauthorized with wrong authorization header" do
    conn =
      build_conn(:get, "/api/endpoint")
      |> Plug.Conn.put_req_header("authorization", "wrong")
      |> AuthTokenCheck.call([])

    assert conn.status == 401
    assert conn.resp_body == "unauthorized"
    assert conn.halted == true
  end

  test "call unauthorized with missing authorization header" do
    conn =
      build_conn(:get, "/api/endpoint")
      |> AuthTokenCheck.call([])

    assert conn.status == 401
    assert conn.resp_body == "unauthorized"
    assert conn.halted == true
  end
end
