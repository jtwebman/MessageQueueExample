defmodule MessageQueueExample.Endpoint do
  @moduledoc """
  A Plug responsible for logging request info, and queuing the messages
  """

  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  def log_processor(name, message) do
    Logger.info("queue #{name}: #{message}")
  end

  # Parse the request for returning 200 if the request has queue and message
  # query string values and 400 if it is missing them
  def parse(conn) do
    with %{"queue" => queue, "message" => message} <- conn.query_params do
      MessageQueueExample.Queue.create(queue, 1000, &log_processor/2)
      MessageQueueExample.Queue.add(queue, message)
      send_resp(conn, 200, "")
    else
      _ ->
        send_resp(
          conn,
          400,
          "GET /receive-message requires queue and message query string params"
        )
    end
  end

  get "/receive-message" do
    Plug.Conn.fetch_query_params(conn)
    |> parse()
  end

  # match all other routes besides /receive-message and return 404
  match _ do
    send_resp(conn, 404, "")
  end
end
