defmodule MuchData do
  use MuchData.Types
  import ExAequo.KeywordParams, only: [tuple_from_params: 3]


  @moduledoc """
  Documentation for `MuchData`.

  ## MuchData

  Reassemble and merge map like data from many sources and many formats.

  - Sources supported in this version: files
  - Formats supported in this version: YAML

  All the examples here are using the fixtures found in [fixtures](https://github.com/RobertDober/much_data/test/fixtures)

  ### Parsing a single file

  Will by default add it's filename

      iex(0)> parse_file("test/fixtures/top1.yml")["top1"]["a"]
      42

  A convenience function is provided to access nested string keys

      iex(1)> parse_file("test/fixtures/top1.yml") |> dig("top1.level1.a")
      {:ok, %{"x" => 1, "y" => 2}}

  The prefix key for the filename can either be removed

      iex(2)> parse_file("test/fixtures/top1.yml", remove_filename: true)
      ...(2)>  |> dig!("level1.a.x")
      1

  Alternatively the whole path of the file can be used as composed key

      iex(3)> parse_file("test/fixtures/top1.yml", expand_path: true)
      %{"test" => %{"fixtures" => %{"top1.yml" => %{"a" => 42, "level1" => %{"a" => %{"x" => 1, "y" => 2}}}}}}
  """

  alias __MODULE__.Error

  @spec dig(map(), binary()) :: NestedMap.result_t
  def dig(map, compound_string_key) do
    keys = String.split(compound_string_key, ".")
    NestedMap.fetch(map, keys)
  end

  @doc false
  @spec dig!(map(), binary()) :: maybe_error(NestedMap.result_t)
  def dig!(map, compound_string_key) do
    case dig(map, compound_string_key) do
      {:ok, value} -> value
      :error       -> raise Error, "compound string key #{compound_string_key} not found"
    end
  end

  @default_options %{ remove_filename: false, expand_path: false }
  @spec parse_file(binary(), Keyword.t) :: maybe_error(map())
  def parse_file(filename, options \\ [])
  def parse_file(filename, options) do
    %{remove_filename: remove_filename, expand_path: expand_path} = Map.merge(@default_options, options |> Enum.into(%{}))
    if remove_filename && expand_path do
      raise Error, "must not specify remove_filename and expand_path"
    end
    result = _parse_file(filename)
    cond do
      remove_filename -> result
      expand_path     -> _make_prefix_map(filename, result)
      true            -> %{Path.basename(filename, Path.extname(filename)) => result}
    end
  end

  @spec parse_tree(binary(), Keyword.t) :: map()
  def parse_tree(path, options \\ [])
  def parse_tree(path, options) do
    {include_name, split_path} = tuple_from_params([include_name: true, split_path: false], options, [:include_name, :split_path])
    cond do
      split_path -> NestedMap.make_nested_map(Path.split(path), _tree_hash(path, options))
      include_name -> %{Path.basename(path) => _tree_hash(path, options)}
      true -> _tree_hash(path, options)
    end
  end

  @doc """
  Used by the `xtra` mix task to generate the latest version in the docs, but
  also handy for client applications for quick exploration in `iex`.
  """
  @spec version() :: binary()
  def version() do
    with {:ok, version} = :application.get_key(:nested_map, :vsn),
      do: to_string(version)
  end

  @spec _add_maps(binaries(), map(), map()) :: map()
  defp _add_maps(prefix, data, parsed)
  defp _add_maps([], data, _parsed), do: data

  defp _add_maps([pfx], data, parsed) do
    Map.put(data, pfx, parsed)
  end

  defp _add_maps([h | t], data, parsed) do
    data1 = Map.put_new(data, h, %{})
    result = _add_maps(t, data1[h], parsed)
    %{data1 | h => result}
  end

  @spec _make_prefix_map(binary(), map()) :: map()
  defp _make_prefix_map(filename, result) do
    (Path.extname(filename) |> Regex.escape) <> "\z"
      |> Regex.compile!
      |> Regex.replace(filename, "")
      |> Path.split
      |> Enum.reverse
      |> Enum.reduce(result, fn key, acc -> %{key => acc} end)
  end

  @spec _parse_file(binary()) :: maybe_error(map())
  defp _parse_file(filename) do
    case YamlElixir.read_from_file(filename) do
      {:ok, result} -> result
      {:error, message} -> raise message
    end
  end

  @spec _parse(prefixed(), map()) :: map()
  defp _parse({file, prefix}, data) do
    parsed = _parse_yml(file)
    # IO.inspect(file, label: :file)
    _add_maps(prefix, data, parsed) # |> IO.inspect(label: "Added maps")
  end

  @spec _parse_yml(String.t) :: map()
  defp _parse_yml(file, options \\ []) do
    result = YamlElixir.read_from_file!(file)
    if Keyword.get(options, :include_filename) do
      Map.put(result, :file, file)
    else
      result
    end
  end

  @spec _tree_hash(binary(), Keyword.t) :: map()
  defp _tree_hash(path, _options) do
    MuchData.FileWalker.walk(path, ".yml", &_parse/2, %{})
  end
end
