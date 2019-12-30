defmodule MessageQueueExample.NodeListener do
  @moduledoc """
  A GenServer that listens to node up and down events and removes and adds 
  them for queue Horde registry and supervisor
  """
  use GenServer

  @doc """
  Start the node listener for dealing with syncing the Horde.Cluster
  """
  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  @impl true
  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, nil}
  end

  # Handle the node up event
  @impl true
  def handle_info({:nodeup, _node, _node_type}, state) do
    set_members(MessageQueueExample.HordeRegistry)
    set_members(MessageQueueExample.HordeSupervisor)

    {:noreply, state}
  end

  # Handle the node down event
  @impl true
  def handle_info({:nodedown, _node, _node_type}, state) do
    set_members(MessageQueueExample.HordeRegistry)
    set_members(MessageQueueExample.HordeSupervisor)
    {:noreply, state}
  end

  # loop through all nodes and add them to the Horde.Cluster
  defp set_members(name) do
    members =
      [Node.self() | Node.list()]
      |> Enum.map(fn node -> {name, node} end)

    :ok = Horde.Cluster.set_members(name, members)
  end
end
