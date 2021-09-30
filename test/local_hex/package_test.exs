defmodule LocalHex.PackageTest do
  use ExUnit.Case, async: true

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
