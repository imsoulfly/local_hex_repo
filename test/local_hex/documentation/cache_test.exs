defmodule LocalHex.Documentation.CacheTest do
  use LocalHex.StorageCase, async: false

  alias LocalHex.Documentation.Cache
  alias LocalHex.Repository

  test "provides cache_path to documentation after lazily downloading it" do
    repository = repository_config()

    expected_file_path =
      Path.join([
        Application.app_dir(:local_hex),
        "priv",
        "static",
        "docs",
        repository.name,
        "example_lib-0.1.0",
        "index.html"
      ])

    {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
    :ok = Repository.publish_docs(repository, "example_lib", "0.1.0", tarball)

    refute File.exists?(expected_file_path)

    {:ok, path} = Cache.cache_path(repository, %{"name" => "example_lib", "version" => "0.1.0"})

    assert path == "/docs/#{repository.name}/example_lib-0.1.0/index.html"
    assert File.exists?(expected_file_path)

    # Also with warmed up cache
    {:ok, path} = Cache.cache_path(repository, %{"name" => "example_lib", "version" => "0.1.0"})
    assert path == "/docs/#{repository.name}/example_lib-0.1.0/index.html"
  end

  test "return :bad_request error on missing params" do
    repository = repository_config()
    {:error, :bad_request} = Cache.cache_path(repository, %{"name" => "example_lib"})
  end

  test "return :not_found error on missing documentation tarball to download" do
    repository = repository_config()

    {:error, :not_found} =
      Cache.cache_path(repository, %{"name" => "example_lib", "version" => "1.0.0"})
  end
end
