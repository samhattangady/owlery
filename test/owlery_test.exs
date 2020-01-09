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
    {:ok, second} = Owlery.TestTaskRunner.start_link(self(), channel_name)
    send(second, :add)
    ExUnit.Assertions.assert_receive(:ok)

    players = Owlery.Channel.get_players(channel_name)
    assert players.two == second
  end

  test "cannot add third player" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    {:ok, first} = Owlery.TestTaskRunner.start_link(self(), channel_name)
    send(first, :add)
    ExUnit.Assertions.assert_receive(:ok)
    {:ok, second} = Owlery.TestTaskRunner.start_link(self(), channel_name)
    send(second, :add)
    ExUnit.Assertions.assert_receive(:ok)
    result = Owlery.Channel.add_as_player(channel_name)
    players = Owlery.Channel.get_players(channel_name)
    assert players.one == first
    assert players.two == second
    assert result == :error
  end

  test "cannot remove player not in channel" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    {:ok, first} = Owlery.TestTaskRunner.start_link(self(), channel_name)
    send(first, :add)
    ExUnit.Assertions.assert_receive(:ok)
    {:ok, second} = Owlery.TestTaskRunner.start_link(self(), channel_name)
    send(second, :add)
    ExUnit.Assertions.assert_receive(:ok)
    result = Owlery.Channel.add_as_player(channel_name)
    players = Owlery.Channel.get_players(channel_name)
    assert players.one == first
    assert players.two == second
    assert result == :error
    result = Owlery.Channel.remove_as_player(channel_name)
    assert players.one == first
    assert players.two == second
    assert result == :error
  end

  test "can add third player after one player exits" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    {:ok, first} = Owlery.TestTaskRunner.start_link(self(), channel_name)
    send(first, :add)
    ExUnit.Assertions.assert_receive(:ok)
    {:ok, second} = Owlery.TestTaskRunner.start_link(self(), channel_name)
    send(second, :add)
    ExUnit.Assertions.assert_receive(:ok)
    result = Owlery.Channel.add_as_player(channel_name)
    players = Owlery.Channel.get_players(channel_name)
    assert players.one == first
    assert players.two == second
    assert result == :error
    send(second, :remove)
    ExUnit.Assertions.assert_receive(:ok)
    result = Owlery.Channel.add_as_player(channel_name)
    players = Owlery.Channel.get_players(channel_name)
    assert players.one == first
    assert players.two == self()
    assert result == :ok
  end

  test "recieve all cells" do
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 5, "col" => 8}, "letter" => "V"})

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 5, "col" => 8}, "letter" => "S"})

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 6, "col" => 8}, "letter" => "A"})

    Owlery.Channel.add_entry(channel_name, %{"cell" => %{"row" => 7, "col" => 8}, "letter" => "M"})

    grid = Owlery.Channel.get_grid(channel_name)
    assert grid == %{"5 8" => "S", "6 8" => "A", "7 8" => "M"}
    Owlery.Channel.request_all_cells(channel_name, self())
    # TODO (30 Dec 2019 sam): See if there is a better/cleaner way of doing this...
    receive do
      {:update_entry,
       %{
         "data" => %{cell: %{"col" => col, "row" => row}, letter: letter},
         "message" => "update_entry"
       }} ->
        case letter do
          "S" ->
            assert row == 5
            assert col == 8

          "A" ->
            assert row == 6
            assert col == 8

          "M" ->
            assert row == 7
            assert col == 8
        end
    end

    receive do
      {:update_entry,
       %{
         "data" => %{cell: %{"col" => col, "row" => row}, letter: letter},
         "message" => "update_entry"
       }} ->
        case letter do
          "S" ->
            assert row == 5
            assert col == 8

          "A" ->
            assert row == 6
            assert col == 8

          "M" ->
            assert row == 7
            assert col == 8
        end
    end

    receive do
      {:update_entry,
       %{
         "data" => %{cell: %{"col" => col, "row" => row}, letter: letter},
         "message" => "update_entry"
       }} ->
        case letter do
          "S" ->
            assert row == 5
            assert col == 8

          "A" ->
            assert row == 6
            assert col == 8

          "M" ->
            assert row == 7
            assert col == 8
        end
    end
  end
end

defmodule Owlery.TestTaskRunner do
  def start_link(parent, name) do
    Task.start_link(fn -> loop(parent, name) end)
  end

  defp loop(parent, name) do
    receive do
      :add ->
        Owlery.Channel.add_as_player(name)
        send(parent, :ok)
        loop(parent, name)

      :remove ->
        Owlery.Channel.remove_as_player(name)
        send(parent, :ok)
        loop(parent, name)
    end
  end
end
