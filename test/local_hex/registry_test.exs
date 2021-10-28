defmodule LocalHex.RegistryTest do
  use ExUnit.Case, async: true

  describe "#add_package" do
    test "#add_package to empty registry" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry = LocalHex.Registry.add_package(%{}, package)

      expected_registry = %{
        "example_lib" => [
          %{
            dependencies: [
              %{
                app: "ex_doc",
                optional: false,
                package: "ex_doc",
                repository: "hexpm",
                requirement: ">= 0.0.0"
              }
            ],
            inner_checksum:
              <<231, 252, 60, 150, 122, 60, 244, 1, 78, 184, 207, 215, 116, 170, 137, 203, 78, 65,
                159, 80, 212, 245, 39, 178, 172, 39, 77, 177, 9, 98, 108, 243>>,
            outer_checksum:
              <<200, 77, 199, 170, 55, 147, 47, 5, 50, 110, 181, 22, 221, 23, 242, 240, 237, 109,
                86, 186, 0, 32, 251, 11, 71, 183, 158, 63, 25, 174, 87, 215>>,
            version: "0.1.0"
          }
        ]
      }

      assert ^expected_registry = registry
    end

    test "#add_package to registry with another version of the package" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry = LocalHex.Registry.add_package(%{}, package)

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.2.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry = LocalHex.Registry.add_package(registry, package)

      expected_registry = %{
        "example_lib" => [
          %{
            dependencies: [
              %{
                app: "ex_doc",
                optional: false,
                package: "ex_doc",
                repository: "hexpm",
                requirement: ">= 0.0.0"
              }
            ],
            inner_checksum:
              <<231, 252, 60, 150, 122, 60, 244, 1, 78, 184, 207, 215, 116, 170, 137, 203, 78, 65,
                159, 80, 212, 245, 39, 178, 172, 39, 77, 177, 9, 98, 108, 243>>,
            outer_checksum:
              <<200, 77, 199, 170, 55, 147, 47, 5, 50, 110, 181, 22, 221, 23, 242, 240, 237, 109,
                86, 186, 0, 32, 251, 11, 71, 183, 158, 63, 25, 174, 87, 215>>,
            version: "0.1.0"
          },
          %{
            dependencies: [
              %{
                app: "ex_doc",
                optional: false,
                package: "ex_doc",
                repository: "hexpm",
                requirement: ">= 0.0.0"
              }
            ],
            inner_checksum:
              <<204, 165, 89, 230, 140, 39, 251, 45, 90, 236, 174, 124, 123, 124, 58, 192, 2, 130,
                183, 9, 107, 245, 68, 155, 252, 128, 228, 172, 36, 47, 1, 209>>,
            outer_checksum:
              <<121, 231, 109, 122, 83, 200, 182, 71, 229, 125, 226, 101, 10, 17, 215, 136, 39,
                197, 161, 170, 236, 120, 58, 136, 29, 14, 221, 121, 44, 191, 121, 100>>,
            version: "0.2.0"
          }
        ]
      }

      assert ^expected_registry = registry
    end

    test "#add_package to registry with another existing package" do
      {:ok, tarball} = File.read("./test/fixtures/another_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry = LocalHex.Registry.add_package(%{}, package)

      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry = LocalHex.Registry.add_package(registry, package)

      expected_registry = %{
        "another_lib" => [
          %{
            dependencies: [
              %{
                app: "ex_doc",
                optional: false,
                package: "ex_doc",
                repository: "hexpm",
                requirement: ">= 0.0.0"
              }
            ],
            inner_checksum:
              <<241, 248, 206, 254, 47, 46, 7, 49, 17, 24, 118, 200, 204, 155, 63, 211, 254, 67,
                243, 192, 56, 194, 157, 56, 209, 157, 110, 255, 58, 50, 0, 64>>,
            outer_checksum:
              <<204, 84, 86, 176, 58, 58, 131, 77, 38, 136, 230, 149, 23, 125, 28, 138, 10, 138,
                1, 204, 51, 80, 124, 187, 150, 18, 108, 238, 93, 94, 144, 2>>,
            version: "0.1.0"
          }
        ],
        "example_lib" => [
          %{
            dependencies: [
              %{
                app: "ex_doc",
                optional: false,
                package: "ex_doc",
                repository: "hexpm",
                requirement: ">= 0.0.0"
              }
            ],
            inner_checksum:
              <<231, 252, 60, 150, 122, 60, 244, 1, 78, 184, 207, 215, 116, 170, 137, 203, 78, 65,
                159, 80, 212, 245, 39, 178, 172, 39, 77, 177, 9, 98, 108, 243>>,
            outer_checksum:
              <<200, 77, 199, 170, 55, 147, 47, 5, 50, 110, 181, 22, 221, 23, 242, 240, 237, 109,
                86, 186, 0, 32, 251, 11, 71, 183, 158, 63, 25, 174, 87, 215>>,
            version: "0.1.0"
          }
        ]
      }

      assert ^expected_registry = registry
    end
  end

  describe "#retire_package_release" do
    test "marks a release as retired" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry =
        LocalHex.Registry.add_package(%{}, package)
        |> LocalHex.Registry.retire_package_release(
          package.name,
          "0.1.0",
          "invalid",
          "some_message"
        )

      result = registry["example_lib"] |> List.first()

      expected_retired = %{
        reason: :RETIRED_INVALID,
        message: "some_message"
      }

      assert Map.has_key?(result, :retired)
      assert ^expected_retired = result.retired
    end

    test "updates the retired state of a release" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry =
        LocalHex.Registry.add_package(%{}, package)
        |> LocalHex.Registry.retire_package_release(
          package.name,
          "0.1.0",
          "invalid",
          "some_message"
        )
        |> LocalHex.Registry.retire_package_release(
          package.name,
          "0.1.0",
          "security",
          "some_other_message"
        )

      result = registry["example_lib"] |> List.first()

      expected_retired = %{
        reason: :RETIRED_SECURITY,
        message: "some_other_message"
      }

      assert Map.has_key?(result, :retired)
      assert ^expected_retired = result.retired
    end

    test "does nothing on missing version" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry =
        LocalHex.Registry.add_package(%{}, package)
        |> LocalHex.Registry.retire_package_release(
          package.name,
          "0.2.0",
          "invalid",
          "some_message"
        )

      result = registry["example_lib"] |> List.first()

      refute Map.has_key?(result, :retired)
    end
  end

  describe "#unretire_package_release" do
    test "removes a :retired entry from a release" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry =
        LocalHex.Registry.add_package(%{}, package)
        |> LocalHex.Registry.retire_package_release(
          package.name,
          "0.1.0",
          "invalid",
          "some_message"
        )

      result = registry["example_lib"] |> List.first()

      assert Map.has_key?(result, :retired)

      registry = LocalHex.Registry.unretire_package_release(registry, package.name, "0.1.0")
      result = registry["example_lib"] |> List.first()

      refute Map.has_key?(result, :retired)
    end

    test "is idempotent" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry =
        LocalHex.Registry.add_package(%{}, package)
        |> LocalHex.Registry.retire_package_release(
          package.name,
          "0.1.0",
          "invalid",
          "some_message"
        )

      result = registry["example_lib"] |> List.first()

      assert Map.has_key?(result, :retired)

      registry =
        LocalHex.Registry.unretire_package_release(registry, package.name, "0.1.0")
        |> LocalHex.Registry.unretire_package_release(package.name, "0.1.0")

      result = registry["example_lib"] |> List.first()

      refute Map.has_key?(result, :retired)
    end

    test "does nothing on missing version" do
      {:ok, tarball} = File.read("./test/fixtures/example_lib-0.1.0.tar")
      {:ok, package} = LocalHex.Package.load_from_tarball(tarball)

      registry =
        LocalHex.Registry.add_package(%{}, package)
        |> LocalHex.Registry.retire_package_release(
          package.name,
          "0.1.0",
          "invalid",
          "some_message"
        )

      result = registry["example_lib"] |> List.first()

      assert Map.has_key?(result, :retired)

      registry = LocalHex.Registry.unretire_package_release(registry, package.name, "0.2.0")
      result = registry["example_lib"] |> List.first()

      assert Map.has_key?(result, :retired)
    end
  end
end
