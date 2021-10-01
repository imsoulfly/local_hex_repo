defmodule LocalHex.DocumentationTest do
  use ExUnit.Case, async: true

  test "#load creates a %Documentation{} from params and tarball" do
    {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
    {:ok, documentation} = LocalHex.Documentation.load("example_lib", "0.1.0", tarball)

    assert documentation.name == "example_lib"
    assert documentation.version == "0.1.0"
    assert documentation.tarball == tarball
  end

  test "#load returns error on invalid tarball" do
    {:ok, tarball} = File.read("./test/fixtures/test_private_key.pem")
    {:error, :invalid} = LocalHex.Documentation.load("example_lib", "0.1.0", tarball)
  end

  test "#load returns error on invalid name" do
    {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
    {:error, :invalid} = LocalHex.Documentation.load("exam+ple_lib", "0.1.0", tarball)
  end

  test "#load returns error on invalid version" do
    {:ok, tarball} = File.read("./test/fixtures/docs/example_lib-0.1.0.tar")
    {:error, :invalid} = LocalHex.Documentation.load("example_lib", "0.1a.0", tarball)
  end
end
