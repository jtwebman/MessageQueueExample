defmodule MessageQueueExample.WorkerTest do
  use ExUnit.Case

  defp via_tuple(name) do
    {:via, Horde.Registry, {MessageQueueExample.HordeRegistry, name}}
  end

  test "Worker can pull one message a second" do
    MessageQueueExample.Queue.create("test", 0, nil)
    test_process = self()

    MessageQueueExample.Worker.start_link("test", 1000, fn name, message ->
      send(test_process, {name, message})
    end)

    GenServer.cast(via_tuple("test"), {:add, "test123"})

    refute_receive({"test", "test123"}, 999, "working processing message too fast")
    assert_receive({"test", "test123"}, 1000)
  end
end
