defmodule Owlery.WebsocketHandler do
  @moduledoc """
  WebsocketHandler, as the name suggests, is in charge of handling all the
  websocket communications. It provides a basic interface with the Channel
  APIs.

  The websocket also holds some state. It mostly holds the name of the
  channel that the client is joined to.

  There are two states that the socket can be in.
  1. In a channel: In this case the client has joined some channel and they
     are in the game. In this case state.name will have some value
  2. Out of channel: In this case, mostly, they are navigating some settings
     and most probably creating a game.
  """
  @behaviour :cowboy_websocket
  require Logger

  # Runs when the websocket connection is requested
  def init(req, _state) do
    Logger.info("websocket init request queries: #{inspect(req.qs)}")
    channel_name = get_query_params(req.qs)["name"]
    {:cowboy_websocket, req, %{:name => channel_name}, %{idle_timeout: 6_000_000}}
  end

  # Runs when the websocket is created. This is where we get the pid
  # for the websocket process itself. If there was a channel name in the request
  # we want to join that channel. Otherwise, we can join a channel at some later
  # point.
  def websocket_init(%{:name => nil} = state) do
    {:ok, state}
  end

  def websocket_init(%{:name => name} = state) do
    Owlery.Channel.start_link(name)
    Owlery.Channel.add_as_player(name)
    {:ok, state}
  end

  def terminate(_reason, _partialReq, state) do
    # TODO (29 Dec 2019 sam): Check if socket is terminated when client closes
    Owlery.Channel.remove_as_player(state.name)
    :ok
  end

  def websocket_handle({:text, content}, state) do
    # TODO (29 Dec 2019 sam): Should we be checking here to see if the socket
    # is already part of a channel? Since channel joining happens in init, it
    # means that messages outside of a channel do not make any sense...
    case Jason.decode(content) do
      {:error, _message} ->
        # TODO (28 Dec 2019 sam): Should this return some error?
        Logger.info("Recieved invalid JSON. Could not decode")
        {[], state}

      {:ok, socket_message} ->
        Logger.info("Processing... #{inspect(socket_message)}")
        process_socket_message(socket_message, state)
    end
  end

  def process_socket_message(%{"message" => "request_all_crosswords"}, state) do
    # Owlery.Channel.request_all_cells(state.name, self())
    {[], state}
  end

  def process_socket_message(%{"message" => "create_new_room"}, state) do
    # Owlery.Channel.request_all_cells(state.name, self())
    {[], state}
  end

  def process_socket_message(%{"message" => "update_entry", "data" => data}, state) do
    Owlery.Channel.add_entry(state.name, data)
    {[], state}
  end

  def process_socket_message(%{"message" => "request_all_cells"}, state) do
    Owlery.Channel.request_all_cells(state.name, self())
    {[], state}
  end

  def process_socket_message(%{"message" => "update_active_clue", "data" => data}, state) do
    Owlery.Channel.update_active_clue(state.name, data)
    {[], state}
  end

  def process_socket_message(message, state) do
    # TODO (28 Dec 2019 sam): Should this return some error?
    Logger.info("Unidentified message: #{message}")
    {[], state}
  end

  def websocket_info({:update_entry, response}, state) do
    Logger.info("Sending update: #{inspect(response)}")
    {:ok, response} = Jason.encode(response)
    {[{:text, response}], state}
  end

  def websocket_info({:update_other_clue, response}, state) do
    Logger.info("Sending update: #{inspect(response)}")
    {:ok, response} = Jason.encode(response)
    {[{:text, response}], state}
  end

  # Private functions
  defp get_query_params(qs) do
    # TODO (28 Dec 2019 sam): Make this a little more robust. Currently, it
    # may crash if given funky inputs
    case qs
         |> String.split("&")
         |> Enum.map(fn s -> String.split(s, "=") end) do
      [[_]] ->
        %{}

      queries ->
        queries
        |> Enum.map(fn [k, v] -> {k, v} end)
        |> Map.new()
    end
  end
end
