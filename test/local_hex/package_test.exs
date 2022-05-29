defmodule LocalHex.PackageTest do
  use ExUnit.Case, async: true

  test "#load_from_filename with only version" do
    {:ok, package} = LocalHex.Package.load_from_filename("example_lib-1.0.1.tar")

    assert package.name == "example_lib"
    assert package.version == "1.0.1"
  end

  test "#load_from_filename with version and pre-release" do
    {:ok, package} =
      LocalHex.Package.load_from_filename("example_lib-1.0.0-alpha.3+20130417140000.amd64.tar")

    assert package.name == "example_lib"
    assert package.version == "1.0.0-alpha.3+20130417140000.amd64"
  end

  test "#load_from_tarball create a %Package{} from tarball" do
    {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
    {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

    assert package.name == "example_lib"
    assert package.version == "0.1.0"
    assert package.tarball == tarball

    assert package.release.version == "0.1.0"

    assert package.release.dependencies == [
             %{
               app: "ex_doc",
               optional: false,
               package: "ex_doc",
               repository: "hexpm",
               requirement: ">= 0.0.0"
             }
           ]
  end
end
