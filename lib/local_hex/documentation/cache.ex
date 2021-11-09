defmodule LocalHex.Documentation.Cache do
  @moduledoc false

  alias LocalHex.{Documentation, Storage}

  def cache_path(repo, %{"name" => name, "version" => version}) do
    %{
      repo: repo,
      documentation: %Documentation{
        name: name,
        version: version
      },
      exists: false
    }
    |> cache_exists?()
    |> ensure_filled_cache()
    |> documentation_path()
  end

  def cache_path(_repo, _params) do
    {:error, :bad_request}
  end

  defp cache_exists?(params) do
    path = Path.join(cache_path(params.repo), documentation_index(params.documentation))

    %{params | exists: File.exists?(path)}
  end

  defp ensure_filled_cache(%{exists: true} = params) do
    params
  end

  defp ensure_filled_cache(params) do
    case Storage.read_docs_tarball(params.repo, params.documentation) do
      {:ok, contents} ->
        tmp_path = Path.join(cache_path(params.repo), "temp.tar.gz")
        File.mkdir_p!(Path.dirname(tmp_path))
        File.write(tmp_path, contents)

        path = Path.join(cache_path(params.repo), documentation_name(params.documentation))
        File.mkdir_p!(Path.dirname(path))
        :erl_tar.extract(tmp_path, [:compressed, {:cwd, path}])

        File.rm(tmp_path)

        %{params | exists: true}

      {:error, _} ->
        params
    end
  end

  defp documentation_path(%{exists: false}) do
    {:error, :not_found}
  end

  defp documentation_path(params) do
    path =
      Path.join([
        "/docs",
        params.repo.name,
        documentation_name(params.documentation),
        "index.html"
      ])

    {:ok, path}
  end

  defp cache_path(repo) do
    Path.join([
      Application.app_dir(:local_hex),
      "priv",
      "static",
      "docs",
      repo.name
    ])
  end

  defp documentation_name(documentation) do
    "#{documentation.name}-#{documentation.version}"
  end

  defp documentation_index(documentation) do
    Path.join(documentation_name(documentation), "index.html")
  end
end
