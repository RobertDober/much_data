defmodule MuchData do
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

  @doc false
  def dig(map, compound_string_key) do
    keys = String.split(compound_string_key, ".")
    NestedMap.fetch(map, keys)
  end

  @doc false
  def dig!(map, compound_string_key) do
    case dig(map, compound_string_key) do
      {:ok, value} -> value
      :error       -> raise Error, "compound string key #{compound_string_key} not found"
    end
  end

  @default_options %{ remove_filename: false, expand_path: false }
  @doc false
  def parse_file(filename, options \\ [])
  def parse_file(filename, options) do
    %{remove_filename: remove_filename, expand_path: expand_path} = Map.merge(@default_options, options |> Enum.into(%{}))
    if remove_filename && expand_path do
      raise Error, "must not specify remove_filename and expand_path"
    end
    result = _parse_file(filename)
    case {remove_filename, expand_path} do
      {true, _} -> result
      {_, true} -> _make_prefix_map(filename, result)
      _         -> %{Path.basename(filename, Path.extname(filename)) => result}
    end
  end

  def parse_tree(path, options \\ [])
  def parse_tree(path, options) do
    # Make a deep hash representing all yml files in the tree
    th = _tree_hash(path, options)
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

  defp _make_prefix_map(filename, result) do
    (Path.extname(filename) |> Regex.escape) <> "\z"
      |> Regex.compile!
      |> Regex.replace(filename, "")
      |> Path.split
      |> Enum.reverse
      |> Enum.reduce(result, fn key, acc -> %{key => acc} end)
  end

  defp _parse_file(filename) do
    case YamlElixir.read_from_file(filename) do
      {:ok, result} -> result
      {:error, message} -> raise message
    end
  end

  defp _tree_hash(path, _options) do
    MuchData.FileWalker.walk(path, ".yml", &_parse/2, %{})
  end

  defp _parse({file, prefix}, data) do
    # parsed = _parse_yml(file)
    _add_maps(prefix, data, file) # |> IO.inspect(label: "Added maps")
  end

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

  defp _parse_yml(file) do
    # |> IO.inspect(label: :parsed)
    YamlElixir.read_from_file!(file)
    |> Map.put(:file, file)
  end
end
