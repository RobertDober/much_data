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

  defp _parse_file(filename) do
    case YamlElixir.read_from_file(filename) do
      {:ok, result} -> result
      {:error, message} -> raise message
    end
  end
end
