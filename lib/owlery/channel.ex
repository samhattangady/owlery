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
            players: []

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name], name: via_tuple(name))
  end

  def add_entry(name, cell_update) do
    GenServer.cast(via_tuple(name), {:add_entry, cell_update})
  end

  def get_grid(name) do
    GenServer.call(via_tuple(name), :get_grid)
  end

  def get_players(name) do
    GenServer.call(via_tuple(name), :get_players)
  end

  def add_player(name, pid) do
    GenServer.cast(via_tuple(name), {:add_player, pid})
  end

  ## Callbacks

  def init([name]) do
    Logger.info("Owl created... Name: #{name}")
    {:ok, %__MODULE__{name: name}}
  end

  def handle_cast({:add_entry, cell_update}, %__MODULE__{grid: grid} = state) do
    new_grid = Map.put(grid, key_from_cell(cell_update["cell"]), cell_update["letter"])
    Enum.map(state.players, fn x -> send(x, {:update_entry, cell_update}) end)
    {:noreply, %__MODULE__{state | grid: new_grid}}
  end

  def handle_cast({:add_player, pid}, %__MODULE__{players: players} = state) do
    Logger.info("Add player... #{state.name}- #{inspect(pid)}")
    {:noreply, %__MODULE__{state | players: [pid|players]}}
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
    %{"row"=> String.to_integer(row), "col"=> String.to_integer(col)}
  end
end
