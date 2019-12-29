defmodule OwleryTest do
  use ExUnit.Case

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

  test "adds one player" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    result = Owlery.Channel.add_as_player(channel_name)
    assert result == :ok
    players = Owlery.Channel.get_players(channel_name)
    assert players.one == self()
  end

  test "removes one player" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    result = Owlery.Channel.add_as_player(channel_name)
    assert result == :ok
    players = Owlery.Channel.get_players(channel_name)
    assert players.one == self()
    Owlery.Channel.remove_as_player(channel_name)
    players = Owlery.Channel.get_players(channel_name)
    assert {players.one, players.two} == {nil, nil}
  end

  test "adds two players" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    result = Owlery.Channel.add_as_player(channel_name)
    assert result == :ok
    players = Owlery.Channel.get_players(channel_name)
    assert players.one == self()
    second = spawn(fn -> Owlery.Channel.add_as_player(channel_name) end)
    Process.monitor(second)

    receive do
      {:DOWN, _, _, _, _} -> "second done"
    end

    players = Owlery.Channel.get_players(channel_name)
    assert players.two == second
  end

  test "cannot add third player" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    first = spawn(fn -> Owlery.Channel.add_as_player(channel_name) end)
    Process.monitor(first)

    receive do
      {:DOWN, _, _, _, _} -> "first done"
    end

    second = spawn(fn -> Owlery.Channel.add_as_player(channel_name) end)
    Process.monitor(second)

    receive do
      {:DOWN, _, _, _, _} -> "second done"
    end

    result = Owlery.Channel.add_as_player(channel_name)
    players = Owlery.Channel.get_players(channel_name)
    IO.puts("#{inspect(players)}")
    assert players.one == first
    assert players.two == second
    assert result == :error
  end

  test "can add thrid player after one player exits" do
    # TODO (29 Dec 2019 sam): implement test...
  end
end
