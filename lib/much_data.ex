defmodule MuchData do
  @moduledoc """
  Documentation for `MuchData`.
  """

  def parse_file(filename, options \\ [])
  def parse_file(filename, options) do
    result = _parse_file(filename)
    if Keyword.get(options, :remove_filename) do
      result
    else
      %{Path.basename(filename, Path.extname(filename)) => result}
    end
  end

  def parse_tree(path, options \\ [])
  def parse_tree(path, options) do
    # Make a deep hash representing all yml files in the tree
    th = _tree_hash(path, options)
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
