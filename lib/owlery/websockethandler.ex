defmodule Owlery.WebsocketHandler do
  @moduledoc """
  WebsocketHandler, as the name suggests, is in charge of handling all the
  websocket communications
  """
  @behaviour :cowboy_websocket
  require Logger

  # Runs when the websocket connection is requested
  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout:  6000000}}
  end

  # Runs when the websocket is created. This is where we get the pid
  # for the websocket process itself.
  def websocket_init(_state) do
    # TODO (27 Dec 2019 sam): Figure out proper workflow for joining channel
    # TODO (27 Dec 2019 sam): Figure out exactly how to get room name
    channel_name = "Hedwig"
    Owlery.Channel.start_link(channel_name)
    Owlery.Channel.add_player(channel_name, self())
    {:ok, %{:name=> channel_name}}
  end

  def terminate(_reason, _partialReq, _state) do
    :ok
  end

  def websocket_handle({:text, content}, state) do
    # TODO (27 Dec 2019 sam): Figure out how to elegantly handle
    # failures of failed JSON decoding?
    {:ok, cell_update} = Jason.decode(content)
    Logger.info("#{inspect(cell_update)}")
    Logger.info("State: #{inspect(state)}")
    Owlery.Channel.add_entry(state.name, cell_update)
    {[], state}
  end

  def websocket_info({:update_entry, response}, state) do
    Logger.info("Sending update: #{inspect(response)}")
    {:ok, response} = Jason.encode(response)
    {[{:text, response}], state}
  end
end
