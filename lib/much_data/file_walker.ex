defmodule MuchData.FileWalker do
  @moduledoc false
  def walk(dir, extension, fun, acc) do
    _walk(dir, [], extension, fun, acc)
  end

  defp _partition(dir) do
    dir
    # |> IO.inspect(lable: :_partition)
    |> File.ls!()
    |> Enum.map(&Path.join(dir, &1))
    |> Enum.group_by(&File.dir?/1)
    |> Enum.into(%{false: [], true: []})
  end

  def _walk(dir, prefixes, extension, fun, acc) do
    %{false: files, true: dirs} = _partition(dir) #|> IO.inspect()

    acc1 =
      Enum.reduce(dirs, acc, fn dir2, acc2 ->
        _walk(dir2, prefixes ++ [dir2|>Path.basename], extension, fun, acc2)
      end)

    files
    |> Enum.filter(&String.ends_with?(&1, extension))
    |> Enum.map(&{&1, prefixes ++ [Path.basename(&1, extension)]})
    |> Enum.reduce(acc1, fun)
  end

end
