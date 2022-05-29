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
               store: {LocalHex.Storage.Local, [root: "priv/test_repos/"]},
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
               store: {LocalHex.Storage.Local, [root: "priv/test_repos/"]},
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

      assert repository.name == "test"
      assert repository.store == {LocalHex.Storage.Local, [root: "priv/test_repos/"]}

      assert repository.private_key ==
               File.read!(Path.expand("../fixtures/test_private_key.pem", __DIR__))

      assert repository.public_key ==
               File.read!(Path.expand("../fixtures/test_public_key.pem", __DIR__))
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
      assert File.exists?(path(repository, ["tarballs", "example_lib", "example_lib-0.1.0.tar"]))
      assert File.exists?(path(repository, ["packages", "example_lib"]))
    end

    test "new package version to repository" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = Repository.publish(repository, tarball)

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.2.0.tar")
      {:ok, repository} = Repository.publish(repository, tarball)

      assert {:ok, [_, _]} = Map.fetch(repository.registry, "example_lib")

      assert File.exists?(path(repository, ["tarballs", "example_lib", "example_lib-0.1.0.tar"]))
      assert File.exists?(path(repository, ["tarballs", "example_lib", "example_lib-0.2.0.tar"]))
    end
  end

  describe "#publish_docs" do
    test "stores documentation tarball" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
      :ok = Repository.publish_docs(repository, "example_lib", "0.1.0", tarball)

      assert File.exists?(path(repository, ["docs", "example_lib", "example_lib-0.1.0.tar"]))
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

  describe "#retire_package_release" do
    test "marks a release as retired" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)

      {:ok, repository} =
        LocalHex.Repository.retire(repository, "example_lib", "0.1.0", "invalid", "some_message")

      result = repository.registry["example_lib"] |> List.first()

      expected_retired = %{
        reason: :RETIRED_INVALID,
        message: "some_message"
      }

      assert Map.has_key?(result, :retired)
      assert ^expected_retired = result.retired
    end

    test "error on missing version" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)

      {:error, :not_found} =
        LocalHex.Repository.retire(repository, "example_lib", "0.2.0", "invalid", "some_message")
    end
  end

  describe "#unretire_package_release" do
    test "removes a :retired entry from a release" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)

      {:ok, repository} =
        LocalHex.Repository.retire(repository, "example_lib", "0.1.0", "invalid", "some_message")

      result = repository.registry["example_lib"] |> List.first()

      assert Map.has_key?(result, :retired)

      {:ok, repository} = LocalHex.Repository.unretire(repository, "example_lib", "0.1.0")
      result = repository.registry["example_lib"] |> List.first()

      refute Map.has_key?(result, :retired)
    end

    test "error on missing version" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)
      {:error, :not_found} = LocalHex.Repository.unretire(repository, "example_lib", "0.2.0")
    end
  end

  describe "#revert" do
    test "removes a release from repository" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)
      {:ok, repository} = LocalHex.Repository.revert(repository, "example_lib", "0.1.0")

      assert Enum.empty?(repository.registry["example_lib"])
    end

    test "error on missing version" do
      repository = repository_config()

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, repository} = LocalHex.Repository.publish(repository, tarball)
      {:error, :not_found} = LocalHex.Repository.revert(repository, "example_lib", "0.2.0")
    end
  end
end
