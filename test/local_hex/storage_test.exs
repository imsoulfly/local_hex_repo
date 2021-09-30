defmodule LocalHex.StorageTest do
  use LocalHex.StorageCase

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
