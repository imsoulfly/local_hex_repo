defmodule LocalHexWeb.PackageHTML do
  use LocalHexWeb, :html

  embed_templates "package_html/*"

  def package_dom_id(package, version) do
    package.name <> "-" <> String.replace(version, ".", "_")
  end

  def package_clipboard(repo, package, version) do
    "{:" <> package.name <> ", \"~> " <> version <> "\", repo: :" <> repo.name <> "}"
  end
end
