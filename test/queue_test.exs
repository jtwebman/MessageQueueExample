defmodule MessageQueueExample.QueueTest do
  use ExUnit.Case

  test "start queue and set and fetch message" do
    MessageQueueExample.Queue.create("test", 0, nil)
    MessageQueueExample.Queue.add("test", "test123")
    assert {:ok, "test123"} = MessageQueueExample.Queue.next("test")
  end

  test "start queue and fetch nothing" do
    MessageQueueExample.Queue.create("test", 0, nil)
    assert :none = MessageQueueExample.Queue.next("test")
  end

  test "start queue and fetch FIFO" do
    MessageQueueExample.Queue.create("test", 0, nil)

    MessageQueueExample.Queue.add("test", "test123")
    MessageQueueExample.Queue.add("test", "test456")
    MessageQueueExample.Queue.add("test", "test789")

    assert {:ok, "test123"} = MessageQueueExample.Queue.next("test")
    assert {:ok, "test456"} = MessageQueueExample.Queue.next("test")
    assert {:ok, "test789"} = MessageQueueExample.Queue.next("test")
  end
end
