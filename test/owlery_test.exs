defmodule OwleryTest do
  use ExUnit.Case
  doctest Owlery

  test "greets the world" do
    assert Owlery.hello() == :world
  end

  test "saves a new entry" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 5, "col" => 8}, "letter" => "V"})

    grid = Owlery.Channel.get_grid(channel_name)
    assert grid["5 8"] == "V"
  end

  test "updates an entry" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 5, "col" => 8}, "letter" => "V"})

    grid = Owlery.Channel.get_grid(channel_name)
    assert grid["5 8"] == "V"

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 5, "col" => 8}, "letter" => "A"})

    grid = Owlery.Channel.get_grid(channel_name)
    assert grid["5 8"] == "A"
  end

  test "returns grid as expected" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 5, "col" => 8}, "letter" => "V"})

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 5, "col" => 8}, "letter" => "S"})

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 6, "col" => 8}, "letter" => "A"})

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 7, "col" => 8}, "letter" => "M"})

    grid = Owlery.Channel.get_grid(channel_name)
    assert grid == %{"5 8" => "S", "6 8" => "A", "7 8" => "M"}
  end
end
