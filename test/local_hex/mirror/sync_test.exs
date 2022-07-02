defmodule LocalHex.Mirror.SyncTest do
  use LocalHex.MirrorCase

  import Mox

  setup :verify_on_exit!

  test "sync with empty list of libraries from API initializes repository" do
    MockHexApi
    |> expect(:fetch_hexpm_names, fn _ -> {:ok, upstream_encode_names([])} end)
    |> expect(:fetch_hexpm_versions, 1, fn _ -> {:ok, upstream_encode_versions([])} end)
    |> expect(:fetch_hexpm_package, 0, fn _, _ -> {:ok, "signed_package"} end)
    |> expect(:fetch_hexpm_tarball, 0, fn _, _, _ -> {200, "tarball"} end)

    Sync.sync(repository())

    repository = Repository.load(repository())
    assert Enum.empty?(repository.registry)

    assert File.exists?(path(repository(), ["names"]))
    assert File.exists?(path(repository(), ["versions"]))
  end

  test "sync with empty list of libraries from API on existing repository with libraries" do
    initial_repository_setup()

    MockHexApi
    |> expect(:fetch_hexpm_names, fn _ -> {:ok, upstream_encode_names([])} end)
    |> expect(:fetch_hexpm_versions, 1, fn _ -> {:ok, upstream_encode_versions([])} end)
    |> expect(:fetch_hexpm_package, 0, fn _, _ -> {:ok, "signed_package"} end)
    |> expect(:fetch_hexpm_tarball, 0, fn _, _, _ -> {200, "tarball"} end)

    Sync.sync(repository())

    repository = Repository.load(repository())
    # deletes entries
    assert Enum.empty?(repository.registry)

    assert File.exists?(path(repository(), ["names"]))
    assert File.exists?(path(repository(), ["versions"]))

    refute File.exists?(path(repository(), ["packages", "example_lib"]))
    refute File.exists?(path(repository(), ["tarballs", "example_lib", "example_lib-0.1.0.tar"]))
    refute File.exists?(path(repository(), ["tarballs", "example_lib", "example_lib-0.2.0.tar"]))
  end

  test "simple sync with 1 library " do
    {:ok, tarball1} = File.read("./test/fixtures/example_lib-0.1.0.tar")
    {:ok, tarball2} = File.read("./test/fixtures/example_lib-0.2.0.tar")

    MockHexApi
    |> expect(:fetch_hexpm_names, fn _ ->
      names =
        [
          %{name: "example_lib", updated_at: %{nanos: 820_498_000, seconds: 1_642_619_042}}
        ]
        |> upstream_encode_names()

      {:ok, names}
    end)
    |> expect(:fetch_hexpm_versions, 1, fn _ ->
      versions =
        [
          %{
            name: "example_lib",
            retired: [],
            versions: ["0.1.0", "0.2.0"]
          }
        ]
        |> upstream_encode_versions()

      {:ok, versions}
    end)
    |> expect(:fetch_hexpm_package, 1, fn _, _ ->
      {:ok, package1} = Package.load_from_tarball(tarball1)
      {:ok, package2} = Package.load_from_tarball(tarball2)

      {:ok, upstream_encode_package("example_lib", [package1, package2])}
    end)
    |> expect(:fetch_hexpm_tarball, 2, fn
      _, _, "0.1.0" -> {:ok, tarball1}
      _, _, "0.2.0" -> {:ok, tarball2}
    end)

    Sync.sync(repository(), "example_lib")
    repository = Repository.load(repository())

    assert Map.has_key?(repository.registry, "example_lib")
    assert File.exists?(path(repository(), ["packages", "example_lib"]))
    assert File.exists?(path(repository(), ["tarballs", "example_lib", "example_lib-0.1.0.tar"]))
    assert File.exists?(path(repository(), ["tarballs", "example_lib", "example_lib-0.2.0.tar"]))
  end

  test "sync including a deleted library on the mirror" do
    {:ok, tarball1} = File.read("./test/fixtures/example_lib-0.1.0.tar")
    {:ok, tarball2} = File.read("./test/fixtures/example_lib-0.2.0.tar")
    {:ok, another_tarball} = File.read("./test/fixtures/another_lib-0.1.0.tar")

    MockHexApi
    |> expect(:fetch_hexpm_names, fn _ ->
      names =
        [
          %{name: "example_lib", updated_at: %{nanos: 820_498_000, seconds: 1_642_619_042}}
        ]
        |> upstream_encode_names()

      {:ok, names}
    end)
    |> expect(:fetch_hexpm_versions, 1, fn _ ->
      versions =
        [
          %{
            name: "example_lib",
            retired: [],
            versions: ["0.1.0", "0.2.0"]
          }
        ]
        |> upstream_encode_versions()

      {:ok, versions}
    end)
    |> expect(:fetch_hexpm_package, 1, fn
      _, "example_lib" ->
        {:ok, package1} = Package.load_from_tarball(tarball1)
        {:ok, package2} = Package.load_from_tarball(tarball2)

        {:ok, upstream_encode_package("example_lib", [package1, package2])}
    end)
    |> expect(:fetch_hexpm_tarball, 2, fn
      _, "example_lib", "0.1.0" -> {:ok, tarball1}
      _, "example_lib", "0.2.0" -> {:ok, tarball2}
    end)

    {:ok, repository} =
      Repository.load(repository())
      |> Repository.publish(another_tarball)

    Repository.save(repository)

    assert Map.has_key?(repository.registry, "another_lib")
    assert File.exists?(path(repository(), ["packages", "another_lib"]))
    assert File.exists?(path(repository(), ["tarballs", "another_lib", "another_lib-0.1.0.tar"]))

    Sync.sync(repository(), "example_lib")
    repository = Repository.load(repository())

    assert Map.has_key?(repository.registry, "example_lib")
    assert File.exists?(path(repository(), ["packages", "example_lib"]))
    assert File.exists?(path(repository(), ["tarballs", "example_lib", "example_lib-0.1.0.tar"]))
    assert File.exists?(path(repository(), ["tarballs", "example_lib", "example_lib-0.2.0.tar"]))

    refute Map.has_key?(repository.registry, "another_lib")
    refute File.exists?(path(repository(), ["packages", "another_lib"]))
    refute File.exists?(path(repository(), ["tarballs", "another_lib", "another_lib-0.1.0.tar"]))
  end
end
