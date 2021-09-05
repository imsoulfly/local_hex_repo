defmodule LocalHex.StorageTest do
  use LocalHex.StorageCase

  describe "write" do
    test "to file in root path" do
      value = "test_string"
      path = "file1"

      :ok = Storage.write(path, value)
      {:ok, ^value} = File.read(path(path))
    end

    test "to file in a subfolder under root path" do
      value = "test_string"
      path = "subfolder/file1"

      :ok = Storage.write(path, value)
      {:ok, ^value} = File.read(path(path))
    end
  end

  describe "read" do
    test "from file in root path" do
      value = "test_string"
      path = "file2"

      :ok = Storage.write(path, value)
      {:ok, ^value} = Storage.read(path)
    end

    test "from file in a subfolder under root path" do
      value = "test_string"
      path = "subfolder/file2"

      :ok = Storage.write(path, value)
      {:ok, ^value} = Storage.read(path)
    end

    test "from non existing file" do
      path = "subfolder/no_file"

      {:error, :not_found} = Storage.read(path)
    end

    test "from subfolder" do
      path = "subfolder"
      File.mkdir_p!(path(path))
      {:error, :eisdir} = Storage.read(path)
    end
  end

  describe "delete" do
    test "file in root path" do
      value = "test_string"
      path = "file3"

      :ok = Storage.write(path, value)
      :ok = Storage.delete(path)
      assert File.exists?(path(path)) == false
    end

    test "file in a subfolder under root path" do
      value = "test_string"
      path = "subfolder/file3"

      :ok = Storage.write(path, value)
      :ok = Storage.delete(path)
      assert File.exists?(path(path)) == false
    end

    test "keeps subfolder" do
      value = "test_string"
      path = "subfolder/file3"

      :ok = Storage.write(path, value)
      :ok = Storage.delete(path)
      assert File.exists?(path("/")) == true
    end

    test "non existing file" do
      path = "subfolder/no_file"

      {:error, :not_found} = Storage.delete(path)
    end

    test "subfolder" do
      path = "subfolder"
      File.mkdir_p!(path(path))

      {:error, :eperm} = Storage.delete(path)
    end
  end
end
