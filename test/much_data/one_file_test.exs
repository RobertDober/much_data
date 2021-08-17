defmodule MuchData.OneFileTest do
  use ExUnit.Case
  import MuchData, only: [parse_file: 1, parse_file: 2]


  test "Just one file" do
    data = parse_file("test/fixtures/top1.yml")
    assert data == %{
      "top1" => %{
        "a" => 42,
        "level1" => %{
          "a" => %{
            "x" => 1,
            "y" => 2
          }
        }
      }
    }
  end

  test "Just one file, no filename" do
    data = parse_file("test/fixtures/top1.yml", remove_filename: true)
    assert data == %{
      "a" => 42,
      "level1" => %{
        "a" => %{
          "x" => 1,
          "y" => 2
        }
      }
    }
  end
end
