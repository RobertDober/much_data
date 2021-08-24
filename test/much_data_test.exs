defmodule MuchDataTest do
  use ExUnit.Case
  doctest MuchData, import: true

  @required_format ~r{\A \d+ \. \d+ \. \d+ \z}x
  test "version" do
    assert Regex.match?(@required_format, MuchData.version)
  end
end
