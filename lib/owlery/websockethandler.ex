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
    Logger.info("initiating websocket. reqs = #{inspect(req)}")
    {:cowboy_websocket, req, %{:name => nil}, %{idle_timeout: 6_000_000}}
  end

  def terminate(_reason, _partialReq, %{:name => channel_name} = state) do
    if channel_name != nil do
      Owlery.Channel.remove_as_player(channel_name)
    end

    :ok
  end

  def websocket_handle({:text, content}, state) do
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

  def process_socket_message(%{"message" => "request_all_crosswords"}, %{:name => nil} = state) do
    crosswords = Owlery.CrosswordManager.get_latest_crosswords()
    {:ok, response} = Jason.encode(%{"message" => "crossword_listing", "data" => crosswords})
    {[{:text, response}], state}
  end

  def process_socket_message(
        %{"message" => "create_channel", "data" => link},
        %{:name => nil} = state
      ) do
    channel_name = Owlery.RandomNameGenerator.get_random_name()
    _ = Owlery.Channel.start_link(channel_name, link)
    Owlery.Channel.add_as_player(channel_name)

    {:ok, response} =
      Jason.encode(%{
        "message" => "channel_details",
        "data" => %{channel_name: channel_name, link: link}
      })

    {[{:text, response}], %{:name => channel_name}}
  end

  def process_socket_message(
        %{"message" => "join_room", "data" => channel_name},
        %{:name => nil} = state
      ) do
    channel_name =
      String.split(channel_name, "/")
      |> List.last()

    lookup = Registry.lookup(:owlery_registry, channel_name)
    case lookup do
      [] -> 
        {:ok, response} =
          Jason.encode(%{"message" => "channel_full", "data" => nil})
          {[{:text, response}], state}
      [_] ->
        link = Owlery.Channel.get_link(channel_name)
        case Owlery.Channel.add_as_player(channel_name) do
          :ok ->
            {:ok, response} =
              Jason.encode(%{
                "message" => "channel_details",
                "data" => %{channel_name: channel_name, link: link}
              })
              {[{:text, response}], %{:name => channel_name}}
          :error ->
            {:ok, response} =
              Jason.encode(%{"message" => "channel_full", "data" => nil})
              {[{:text, response}], state}
        end
    end
  end

  def process_socket_message(
        %{"message" => "rejoin_room", "data" => channel_name},
        %{:name => nil} = state
      ) do
    channel_name =
      String.split(channel_name, "/")
      |> List.last()

    case Owlery.Channel.add_as_player(channel_name) do
      :ok ->
          {[], %{:name => channel_name}}
      :error ->
        {:ok, response} =
          Jason.encode(%{"message" => "channel_full", "data" => nil})
          {[{:text, response}], state}
    end
  end


  def process_socket_message(
        %{"message" => "update_entry", "data" => data},
        %{:name => channel_name} = state
      ) do
    Owlery.Channel.add_entry(channel_name, data)
    {[], state}
  end

  def process_socket_message(
        %{"message" => "request_all_cells"},
        %{:name => channel_name} = state
      ) do
    Owlery.Channel.request_all_cells(channel_name, self())
    {[], state}
  end

  def process_socket_message(
        %{"message" => "update_active_clue", "data" => data},
        %{:name => channel_name} = state
      ) do
    Owlery.Channel.update_active_clue(channel_name, data)
    {[], state}
  end

  def process_socket_message(
        %{"message" => "leave_room"},
        %{:name => channel_name}
      ) do
    Owlery.Channel.remove_as_player(channel_name)
    crosswords = Owlery.CrosswordManager.get_latest_crosswords()
    {:ok, response} = Jason.encode(%{"message" => "crossword_listing", "data" => crosswords})
    {[{:text, response}], %{:name => nil}}
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
  defp _get_query_params(qs) do
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
