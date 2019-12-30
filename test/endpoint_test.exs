defmodule MessageQueueExample.EndpointTest do
  use ExUnit.Case
  use Plug.Test

  test "/receive-message with queue and message returns 200" do
    response =
      conn(:get, "/receive-message?queue=test&message=test123")
      |> MessageQueueExample.Endpoint.call([])

    assert response.status == 200
  end

  test "/receive-message missing queue returns 400" do
    response =
      conn(:get, "/receive-message?message=test123")
      |> MessageQueueExample.Endpoint.call([])

    assert response.status == 400
  end

  test "/receive-message missing message returns 400" do
    response =
      conn(:get, "/receive-message?queue=test")
      |> MessageQueueExample.Endpoint.call([])

    assert response.status == 400
  end

  test "any route beside /receive-message returns 404" do
    response =
      conn(:get, "/")
      |> MessageQueueExample.Endpoint.call([])

    assert response.status == 404
  end
end
