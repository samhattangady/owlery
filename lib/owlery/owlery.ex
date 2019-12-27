defmodule Owlery.Owlery do
  @moduledoc """
  Owl is a websocket server for cluegrid. It allows players to
  collaboratively solve crossword puzzles. It functions by passing
  websocket messages between the players. It currently supports the
  following kinds of messages.
    1. Cell Update
        Whenever either player updates any cell in the cluegrid, they
        use this message to inform the server. The server then sends
        the same message to all connected players, and they can use it
        to update their state as well
    2. Grid Refresh
        In case of a new player joining, or any other kind of suspected
        loss of state on the frontend, the server will send the entire
        state of the board to the player that requested it.
  """

  def start(_, _) do
    dispatch_config = build_dispatch_config()

    {:ok, _} =
      :cowboy.start_clear(
        :http,
        [{:port, 8080}],
        %{env: %{dispatch: dispatch_config}}
      )
  end

  def build_dispatch_config do
    :cowboy_router.compile([
      {:_,
       [
         {"/", Owlery.WebsocketHandler, []}
       ]}
    ])
  end
end
