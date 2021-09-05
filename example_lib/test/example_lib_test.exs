defmodule ExampleLibTest do
  use ExUnit.Case
  doctest ExampleLib

  test "greets the world" do
    assert ExampleLib.hello() == :world
  end
end
