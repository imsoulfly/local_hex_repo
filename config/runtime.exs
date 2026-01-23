import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  fetch_env! = fn name ->
    System.get_env(name) ||
      raise """
      environment variable #{name} is missing.
      """
  end

  read_key! = fn pem_env, path_env ->
    case System.get_env(pem_env) do
      pem when is_binary(pem) and pem != "" ->
        pem

      _ ->
        path = fetch_env!.(path_env)
        File.read!(path)
    end
  end

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")
  scheme = System.get_env("PHX_URL_SCHEME") || "http"

  url_port =
    System.get_env("PHX_URL_PORT") ||
      if scheme == "https" do
        "443"
      else
        "80"
      end

  config :local_hex, LocalHexWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    url: [host: host, port: String.to_integer(url_port), scheme: scheme],
    secret_key_base: secret_key_base,
    server: true

  # LocalHex (required in prod for the app to boot)
  auth_token = fetch_env!.("LOCAL_HEX_AUTH_TOKEN")
  repo_name = System.get_env("LOCAL_HEX_REPO_NAME") || "local_hex"

  store =
    case (System.get_env("LOCAL_HEX_STORE") || "local") do
      "local" ->
        root = System.get_env("LOCAL_HEX_REPO_ROOT") || "/data/repos"
        {LocalHex.Storage.Local, root: root}

      "s3" ->
        bucket = fetch_env!.("LOCAL_HEX_S3_BUCKET")
        region = System.get_env("AWS_REGION") || System.get_env("AWS_DEFAULT_REGION") || "us-east-1"

        # Support IRSA (AWS_ROLE_ARN + AWS_WEB_IDENTITY_TOKEN_FILE) via ex_aws_sts.
        #
        # This opts into ExAws' awscli auth cache, but avoids reading ~/.aws files by
        # providing an empty in-memory profile and letting the adapter read env vars.
        if System.get_env("AWS_ROLE_ARN") && System.get_env("AWS_WEB_IDENTITY_TOKEN_FILE") do
          config :ex_aws,
            region: region,
            json_codec: Jason,
            access_key_id: [{:awscli, "irsa", 30}],
            secret_access_key: [{:awscli, "irsa", 30}],
            awscli_auth_adapter: ExAws.STS.AuthCache.AssumeRoleWebIdentityAdapter,
            awscli_credentials: %{"irsa" => %{}}

          config :ex_aws, :s3, region: region
        end

        {LocalHex.Storage.S3, bucket: bucket, options: [region: region]}

      other ->
        raise "Unsupported LOCAL_HEX_STORE=#{inspect(other)} (expected \"local\" or \"s3\")"
    end

  private_key = read_key!.("LOCAL_HEX_PRIVATE_KEY_PEM", "LOCAL_HEX_PRIVATE_KEY_PATH")
  public_key = read_key!.("LOCAL_HEX_PUBLIC_KEY_PEM", "LOCAL_HEX_PUBLIC_KEY_PATH")

  mirror_enabled? = (System.get_env("LOCAL_HEX_MIRROR_ENABLED") || "false") == "true"

  upstream_public_key =
    if mirror_enabled? do
      read_key!.(
        "LOCAL_HEX_MIRROR_UPSTREAM_PUBLIC_KEY_PEM",
        "LOCAL_HEX_MIRROR_UPSTREAM_PUBLIC_KEY_PATH"
      )
    end

  mirror_repo =
    if mirror_enabled? do
      [
        name: System.get_env("LOCAL_HEX_MIRROR_REPO_NAME") || "#{repo_name}_mirror",
        store: store,
        private_key: private_key,
        public_key: public_key,
        options: %{
          sync_interval: String.to_integer(System.get_env("LOCAL_HEX_MIRROR_SYNC_INTERVAL_MS") || "3600000"),
          sync_opts: [max_concurrency: 5, timeout: 60000],
          sync_on_demand: true,
          upstream_name: System.get_env("LOCAL_HEX_MIRROR_UPSTREAM_NAME") || "hexpm",
          upstream_url: System.get_env("LOCAL_HEX_MIRROR_UPSTREAM_URL") || "https://repo.hex.pm",
          upstream_public_key: upstream_public_key
        }
      ]
    else
      nil
    end

  repositories =
    if mirror_repo do
      [
        main: [
          name: repo_name,
          store: store,
          private_key: private_key,
          public_key: public_key
        ],
        mirror: mirror_repo
      ]
    else
      [
        main: [
          name: repo_name,
          store: store,
          private_key: private_key,
          public_key: public_key
        ]
      ]
    end

  config :local_hex,
    auth_token: auth_token,
    repositories: repositories

  # Additional mimetype to describe release packages
  config :mime, :types, %{
    "application/vnd.hex+erlang" => ["hex"]
  }

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :local_hex, LocalHexWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.
end
