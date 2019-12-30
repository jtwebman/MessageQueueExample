defmodule MessageQueueExample.QueueHandoff do
  @moduledoc """
  A queue handoff that is just to handle starting new queue with previous messages
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Called from other nodes to handoff.
  Delays the call for 3 seconds to make sure previous queue finishes shutdown
  and new one started which isn't the best strategy as the newly starte queue
  might get items and process them before this one as well as it might take longer
  then 3 seconds in a cluster under heavy load. Like I called out in the queue 
  terminate it would be better to store items in the db and on handle_continue after
  init we pull the records not processed from a db.
  """
  def handoff(name, messages) do
    Process.send_after(__MODULE__, {:handoff, name, messages}, 3000)
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  # Call handoff in queue to add messages not processed from previous nodes
  @impl true
  def handle_info({:handoff, name, messages}, state) do
    MessageQueueExample.Queue.handoff(name, messages)
    {:noreply, state}
  end
end
