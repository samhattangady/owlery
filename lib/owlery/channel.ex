defmodule Owlery.Channel do
  @moduledoc """
  Channel is a GenServer that represents a single channel. Clients will register
  themselves with a Channel,  and will be allowed to recieve and send messages to
  and from it.
  """

  use GenServer
  require Logger

  @owlery_registry :owlery_registry

  defstruct name: "",
            grid: %{},
            players: %{:one => nil, :two => nil}

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name], name: via_tuple(name))
  end

  def add_entry(name, cell_update) do
    GenServer.cast(via_tuple(name), {:add_entry, cell_update})
  end

  def get_grid(name) do
    GenServer.call(via_tuple(name), :get_grid)
  end

  def request_all_cells(name, requester) do
    GenServer.cast(via_tuple(name), {:request_all_cells, requester})
  end

  def get_players(name) do
    GenServer.call(via_tuple(name), :get_players)
  end

  def add_as_player(name) do
    GenServer.call(via_tuple(name), :add_as_player)
  end

  def remove_as_player(name) do
    GenServer.call(via_tuple(name), :remove_as_player)
  end

  ## Callbacks

  def init([name]) do
    Logger.info("Owl created... Name: #{name}")
    {:ok, %__MODULE__{name: name}}
  end

  def handle_cast({:add_entry, cell_update}, %__MODULE__{grid: grid} = state) do
    new_grid = Map.put(grid, key_from_cell(cell_update["cell"]), cell_update["letter"])

    state.players
    |> Enum.map(fn pid -> send_cell_update(pid, cell_update) end)

    {:noreply, %__MODULE__{state | grid: new_grid}}
  end

  def handle_cast({:request_all_cells, requester}, %__MODULE__{grid: grid} = state) do
    Logger.info("Handling request all cells cast")

    grid
    # |> Enum.map(&cell_update_from_grid/1)
    |> Enum.map(fn {key, letter} -> %{letter: letter, cell: cell_from_key(key)} end)
    |> Enum.map(fn cell_update -> send_cell_update(requester, cell_update) end)

    {:noreply, state}
  end

  def handle_call(:add_as_player, {player_pid, _reference}, %__MODULE__{players: players} = state) do
    Logger.info("Trying to add player... #{state.name}- #{inspect(player_pid)}")
    # Try adding as player one. Else add as player two. Else fail
    case {players.one, players.two} do
      {nil, _} ->
        new_players = %{players | :one => player_pid}
        {:reply, :ok, %__MODULE__{state | players: new_players}}

      {_, nil} ->
        new_players = %{players | :two => player_pid}
        {:reply, :ok, %__MODULE__{state | players: new_players}}

      {_, _} ->
        Logger.info("No room in channel. Sorry goodnight")
        {:reply, :error, state}
    end
  end

  def handle_call(
        :remove_as_player,
        {player_pid, _reference},
        %__MODULE__{players: players} = state
      ) do
    Logger.info("Trying to remove player... #{state.name}- #{inspect(player_pid)}")
    # Try adding as player one. Else add as player two. Else fail
    case {players.one, players.two} do
      {player_pid, _} ->
        new_players = %{players | :one => nil}
        {:reply, :ok, %__MODULE__{state | players: new_players}}

      {_, player_pid} ->
        new_players = %{players | :two => nil}
        {:reply, :ok, %__MODULE__{state | players: new_players}}

      {_, _} ->
        Logger.info("Not currently in channel. Could not be removed")
        {:reply, :error, state}
    end
  end

  def handle_call(:get_grid, _from, state) do
    {:reply, state.grid, state}
  end

  def handle_call(:get_players, _from, state) do
    {:reply, state.players, state}
  end

  ## Private Functions

  defp via_tuple(name) do
    {:via, Registry, {@owlery_registry, name}}
  end

  defp key_from_cell(cell) do
    "#{cell["row"]} #{cell["col"]}"
  end

  defp cell_from_key(key) do
    [row, col] = String.split(key)
    %{"row" => String.to_integer(row), "col" => String.to_integer(col)}
  end

  defp cell_update_from_grid({key, letter}) do
    %{letter: letter, cell: cell_from_key(key)}
  end

  defp send_cell_update(pid, cell_update) do
    send(pid, {:update_entry, %{"message" => "update_entry", "data" => cell_update}})
  end
end
