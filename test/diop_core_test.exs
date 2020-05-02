defmodule DiopCoreTest do
  use ExUnit.Case
  doctest DiopCore

  test "greets the world" do
    assert DiopCore.hello() == :world
  end
end
