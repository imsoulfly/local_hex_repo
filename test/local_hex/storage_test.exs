defmodule LocalHex.StorageTest do
  use LocalHex.StorageCase

  alias LocalHex.{Documentation, Package}

  setup do
    {:ok, repository: repository_config()}
  end

  describe "write" do
    test "to file in root path", %{repository: repository} do
      value = "test_string"
      path = "file1"

      :ok = Storage.write(repository, path, value)
      {:ok, ^value} = File.read(path(repository, path))
    end

    test "to file in a subfolder under root path", %{repository: repository} do
      value = "test_string"
      path = "subfolder/file1"

      :ok = Storage.write(repository, path, value)
      {:ok, ^value} = File.read(path(repository, path))
    end
  end

  describe "read" do
    test "from file in root path", %{repository: repository} do
      value = "test_string"
      path = "file2"

      :ok = Storage.write(repository, path, value)
      {:ok, ^value} = Storage.read(repository, path)
    end

    test "from file in a subfolder under root path", %{repository: repository} do
      value = "test_string"
      path = "subfolder/file2"

      :ok = Storage.write(repository, path, value)
      {:ok, ^value} = Storage.read(repository, path)
    end

    test "from non existing file", %{repository: repository} do
      path = "subfolder/no_file"

      {:error, :not_found} = Storage.read(repository, path)
    end

    test "from subfolder", %{repository: repository} do
      path = "subfolder"
      File.mkdir_p!(path(repository, path))
      {:error, :eisdir} = Storage.read(repository, path)
    end
  end

  describe "read/write" do
    test "#read/write_repository", %{repository: repository} do
      value = "test_string"
      :ok = Storage.write_repository(repository, value)
      {:ok, ^value} = Storage.read_repository(repository)
    end

    test "#read/write_names", %{repository: repository} do
      value = "test_string"
      :ok = Storage.write_names(repository, value)
      {:ok, ^value} = Storage.read_names(repository)
    end

    test "#read/write_versions", %{repository: repository} do
      value = "test_string"
      :ok = Storage.write_versions(repository, value)
      {:ok, ^value} = Storage.read_versions(repository)
    end

    test "#read/write_package", %{repository: repository} do
      value = "test_string"
      :ok = Storage.write_package(repository, "test_package", value)
      {:ok, ^value} = Storage.read_package(repository, "test_package")
    end

    test "#read/write_package_tarball", %{repository: repository} do
      package = %Package{
        name: "test_package",
        version: "1.0.0",
        release: %{},
        tarball: "test_tarball_fake"
      }

      :ok = Storage.write_package_tarball(repository, package)
      {:ok, tarball_content} = Storage.read_package_tarball(repository, "test_package-1.0.0.tar")
      assert tarball_content == "test_tarball_fake"
    end

    test "#read/write_docs_package", %{repository: repository} do
      documentation = %Documentation{
        name: "test_package",
        version: "1.0.0",
        tarball: "test_tarball_fake"
      }

      :ok = Storage.write_docs_tarball(repository, documentation)
      {:ok, tarball_content} = Storage.read_docs_tarball(repository, "test_package-1.0.0.tar")
      assert tarball_content == "test_tarball_fake"
    end
  end

  describe "delete" do
    test "file in root path", %{repository: repository} do
      value = "test_string"
      path = "file3"

      :ok = Storage.write(repository, path, value)
      :ok = Storage.delete(repository, path)
      assert File.exists?(path(repository, path)) == false
    end

    test "file in a subfolder under root path", %{repository: repository} do
      value = "test_string"
      path = "subfolder/file3"

      :ok = Storage.write(repository, path, value)
      :ok = Storage.delete(repository, path)
      assert File.exists?(path(repository, path)) == false
    end

    test "keeps subfolder", %{repository: repository} do
      value = "test_string"
      path = "subfolder/file3"

      :ok = Storage.write(repository, path, value)
      :ok = Storage.delete(repository, path)
      assert File.exists?(path(repository, "/")) == true
    end

    test "non existing file", %{repository: repository} do
      path = "subfolder/no_file"

      {:error, :not_found} = Storage.delete(repository, path)
    end

    test "subfolder", %{repository: repository} do
      path = "subfolder"
      File.mkdir_p!(path(repository, path))

      {:error, :eperm} = Storage.delete(repository, path)
    end
  end
end
