defmodule LocalHex.Repo do
  use Ecto.Repo,
    otp_app: :local_hex,
    adapter: Ecto.Adapters.MyXQL
end
