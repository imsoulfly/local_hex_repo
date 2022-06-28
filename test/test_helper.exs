Mox.defmock(LocalHex.Mirror.MockHexApi, for: LocalHex.Mirror.HexApi)
Application.put_env(:local_hex, :hex_api, LocalHex.Mirror.MockHexApi)

ExUnit.start()
