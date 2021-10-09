defmodule LocalHex.RepositoryTest do
  use LocalHex.StorageCase

  alias LocalHex.Repository

  describe "#init" do
    test "a repository with config" do
      repository =
        Application.fetch_env!(:local_hex, :repositories)
        |> Keyword.fetch!(:main)
        |> Repository.init()

      assert repository == %Repository{
               name: "test",
               store: :local,
               registry: %{},
               private_key: File.read!(Path.expand("../fixtures/test_private_key.pem", __DIR__)),
               public_key: File.read!(Path.expand("../fixtures/test_public_key.pem", __DIR__))
             }
    end
  end

  describe "#load" do
    test "a fresh repository" do
      repository =
        Application.fetch_env!(:local_hex, :repositories)
        |> Keyword.fetch!(:main)
        |> Repository.init()
        |> Repository.load()

      assert repository == %Repository{
               name: "test",
               store: :local,
               registry: %{},
               private_key: File.read!(Path.expand("../fixtures/test_private_key.pem", __DIR__)),
               public_key: File.read!(Path.expand("../fixtures/test_public_key.pem", __DIR__))
             }
    end

    test "a repository again after storing" do
      repository =
        Application.fetch_env!(:local_hex, :repositories)
        |> Keyword.fetch!(:main)
        |> Repository.init()
        |> Repository.load()
        |> Repository.save()
        |> Repository.load()

      assert File.exists?(path(repository, ["test.bin"]))

      assert repository == %Repository{
               name: "test",
               store: :local,
               registry: %{},
               private_key: File.read!(Path.expand("../fixtures/test_private_key.pem", __DIR__)),
               public_key: File.read!(Path.expand("../fixtures/test_public_key.pem", __DIR__))
             }
    end
  end

  describe "#publish" do
    test "package to fresh repository" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")

      {:ok, repository} = Repository.publish(repository, tarball)

      assert {:ok, [_]} = Map.fetch(repository.registry, "example_lib")

      assert File.exists?(path(repository, ["versions"]))
      assert File.exists?(path(repository, ["names"]))
      assert File.exists?(path(repository, ["tarballs", "example_lib-0.1.0.tar"]))
      assert File.exists?(path(repository, ["packages", "example_lib"]))
    end

    test "new package version to repository" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = Repository.publish(repository, tarball)

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.2.0.tar")
      {:ok, repository} = Repository.publish(repository, tarball)

      assert {:ok, [_, _]} = Map.fetch(repository.registry, "example_lib")

      assert File.exists?(path(repository, ["tarballs", "example_lib-0.1.0.tar"]))
      assert File.exists?(path(repository, ["tarballs", "example_lib-0.2.0.tar"]))
    end
  end

  describe "#publish_docs" do
    test "stores documentation tarball" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
      :ok = Repository.publish_docs(repository, "example_lib", "0.1.0", tarball)

      assert File.exists?(path(repository, ["docs", "example_lib-0.1.0.tar"]))
    end

    test "fails on invalid name" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
      {:error, :invalid} = Repository.publish_docs(repository, "exa+mple_lib", "0.1.0", tarball)
    end

    test "fails on invalid version" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
      {:error, :invalid} = Repository.publish_docs(repository, "example_lib", "0.1a.0", tarball)
    end
  end
end
