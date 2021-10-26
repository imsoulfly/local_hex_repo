# LocalHex

Make hosting Erlang and Elixir libraries in your local environment easy

## Local setup


To start the local runtime:

```
mix deps.get
mix phx.server
```

To add the local_hex repo to your local `hex` configuration:

```
wget -q http://localhost:4000/public_key
mix hex.repo add local_hex_dev http://localhost:4000 --public-key public_key
rm -f public_key
```
