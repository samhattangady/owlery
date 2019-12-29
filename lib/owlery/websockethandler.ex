defmodule Owlery.WebsocketHandler do
  @moduledoc """
  WebsocketHandler, as the name suggests, is in charge of handling all the
  websocket communications
  """
  @behaviour :cowboy_websocket
  require Logger

  # Runs when the websocket connection is requested
  def init(req, _state) do
    Logger.info("websocket init request queries: #{inspect(req.qs)}")

    channel_name =
      case get_query_params(req.qs)["name"] do
        nil -> "Janani"
        name -> name
      end

    Logger.info("name: #{channel_name}")
    {:cowboy_websocket, req, %{:name => channel_name}, %{idle_timeout: 6_000_000}}
  end

  # Runs when the websocket is created. This is where we get the pid
  # for the websocket process itself.
  def websocket_init(state) do
    Owlery.Channel.start_link(state.name)
    Owlery.Channel.add_player(state.name, self())
    {:ok, state}
  end

  def terminate(_reason, _partialReq, _state) do
    # TODO (29 Dec 2019 sam): Remove self from owlery channel
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

  def process_socket_message(%{"message" => "update_entry", "data" => data}, state) do
    Owlery.Channel.add_entry(state.name, data)
    {[], state}
  end

  def process_socket_message(%{"message" => "request_all_cells"}, state) do
    Owlery.Channel.request_all_cells(state.name, self())
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
