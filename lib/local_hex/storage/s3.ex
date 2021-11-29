defmodule LocalHex.Storage.S3 do
  @moduledoc """
  Adapter module to provide S3 abilities

  In the config files (ex. config.exs) you can configure each repository individually by
  providing a `:store` field that contains a tuple with the details.

  Additionally you need to configure `ex_aws` as well to be able to connect properly to a server and bucket
  of your choice. More details you find here [ExAWS](https://github.com/ex-aws/ex_aws/blob/master/lib/ex_aws/config.ex)
  ```
  config :ex_aws, :s3,
    access_key_id: "123456789",
    secret_access_key: "123456789",
    scheme: "http://",
    host: "localhost",
    port: 9000,
    region: "local"

  storage_config =
    {LocalHex.Storage.S3,
     bucket: "localhex",
     options: [
       region: "local"
     ]}

  config :local_hex,
    auth_token: "local_token",
    repositories: [
      main: [
        name: "local_hex_dev",
        store: storage_config,
        ...
      ]
    ]

  ```
  """

  @behaviour LocalHex.Storage

  require Logger

  alias ExAws.S3

  defstruct [:bucket, :options]

  @impl true
  def write(repository, path, value) do
    s3_config = s3_config_for_repository(repository)
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :write, path}))

    request = S3.put_object(s3_config.bucket, path, value, s3_config.options)

    case ExAws.request(request, s3_config.options) do
      {:ok, _} ->
        :ok

      {:error, _} ->
        {:error, :bad_request}
    end
  end

  @impl true
  def read(repository, path) do
    s3_config = s3_config_for_repository(repository)
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :read, path}))

    request = S3.get_object(s3_config.bucket, path, s3_config.options)

    case ExAws.request(request, s3_config.options) do
      {:ok, %{body: body}} ->
        {:ok, body}

      {:error, {:http_error, 404, _}} ->
        {:error, :not_found}

      other ->
        other
    end
  end

  @impl true
  def delete(repository, path) do
    s3_config = s3_config_for_repository(repository)
    path = path(repository, path)
    Logger.debug(inspect({__MODULE__, :delete, path}))

    request = S3.delete_object(s3_config.bucket, path, s3_config.options)

    case ExAws.request(request, s3_config.options) do
      {:ok, _} ->
        :ok

      {:error, {:http_error, 404, _}} ->
        {:error, :not_found}

      other ->
        other
    end
  end

  defp path(repository, path) do
    Path.join(["", repository.name | List.wrap(path)])
  end

  defp s3_config_for_repository(repository) do
    {_, config} = repository.store
    struct!(__MODULE__, config)
  end
end
