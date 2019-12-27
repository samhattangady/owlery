defmodule OwleryTest do
  use ExUnit.Case
  doctest Owlery

  test "greets the world" do
    assert Owlery.hello() == :world
  end
end
