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
    :ok
  end

  def websocket_handle({:text, content}, state) do
    # TODO (27 Dec 2019 sam): Figure out how to elegantly handle
    # failures of failed JSON decoding?
    case Jason.decode(content) do
      {:error, _message} ->
        # TODO (28 Dec 2019 sam): Should this return some error?
        Logger.info("Recieved invalid JSON. Could not decode")
        {[], state}

      {:ok, socket_message} ->
        case socket_message["message"] do
          "update_entry" ->
            case state.name do
              nil ->
                Logger.info("#{inspect(socket_message)}")
                Logger.info("Client is not part of any channel. Cannot add entry")
                {[], state}

              _ ->
                Logger.info("#{inspect(socket_message)}")
                Owlery.Channel.add_entry(state.name, socket_message["data"])
                {[], state}
            end

          "request_all_cells" ->
            Logger.info("Requesting all cells in grid")
            Owlery.Channel.request_all_cells(state.name, self())
            {[], state}

          message ->
            Logger.info("Unidentified message: #{message}")
            {[], state}
        end
    end
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
