defmodule MuchData.ManyFilesTest do
  use ExUnit.Case
  import MuchData, only: [parse_tree: 1, parse_tree: 2]

  describe "No recursion" do

    test "because no subdirs" do
      data = parse_tree("test/fixtures/level1")
      assert data == %{
        "level1" => %{
          "a" => %{
          },
          "b" => %{
          }
        }
      }
    end
  end

end
