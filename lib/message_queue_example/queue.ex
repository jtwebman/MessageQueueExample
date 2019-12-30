defmodule MessageQueueExample.Queue do
  @moduledoc """
  Used to store a queue for adding and getting next item in queue
  """
  use GenServer

  def child_spec(name, delay_in_milliseconds, call_on) do
    %{id: name, start: {__MODULE__, :start_link, [name, delay_in_milliseconds, call_on]}}
  end

  @doc """
  Start a queue by name
  """
  def start_link(name, delay_in_milliseconds, call_on) do
    GenServer.start_link(__MODULE__, {name, delay_in_milliseconds, call_on}, name: via_tuple(name))
  end

  @doc """
  Create one queue with this name in the cluster
  """
  def create(name, delay_in_milliseconds, call_on) do
    Horde.DynamicSupervisor.start_child(
      MessageQueueExample.HordeSupervisor,
      __MODULE__.child_spec(name, delay_in_milliseconds, call_on)
    )
  end

  @doc """
  Adds a message to the queue by queue name
  """
  def add(name, message) do
    GenServer.cast(via_tuple(name), {:add, message})
  end

  @doc """
  Handoff called on another random node to start a new queue with messages
  """
  def handoff(name, messages) do
    GenServer.call(via_tuple(name), {:handoff, messages})
  end

  @doc """
  Fetch next item from the queue
  """
  def next(name) do
    GenServer.call(via_tuple(name), :next)
  end

  # Gets the tuple for looking up the queue service by name
  defp via_tuple(name) do
    {:via, Horde.Registry, {MessageQueueExample.HordeRegistry, name}}
  end

  # Init genserver with name and empty message list as well as start worker task
  @impl true
  def init({name, delay_in_milliseconds, call_on}) do
    IO.puts("Start queue #{name}")
    Process.flag(:trap_exit, true)
    {:ok, {name, [], nil}, {:continue, {:worker, name, delay_in_milliseconds, call_on}}}
  end

  # if call on is not passed just start queue only
  @impl true
  def handle_continue({:worker, _, _, nil}, state) do
    {:noreply, state}
  end

  # if call on passed start a worker
  @impl true
  def handle_continue({:worker, name, delay_in_milliseconds, call_on}, {name, messages, _}) do
    {:ok, worker_pid} =
      MessageQueueExample.Worker.start_link(name, delay_in_milliseconds, call_on)

    {:noreply, {name, messages, worker_pid}}
  end

  # Handle the add message cast
  @impl true
  def handle_cast({:add, message}, {name, messages, worker_pid}) do
    {:noreply, {name, messages ++ [message], worker_pid}}
  end

  # Handle handoff to other nodes on shutdown
  @impl true
  def handle_call({:handoff, handoff_messages}, _from, {name, messages, worker_pid}) do
    {:reply, :ok, {name, handoff_messages ++ messages, worker_pid}}
  end

  # Handle the get next message call with no messages
  @impl true
  def handle_call(:next, _from, {name, [], worker_pid}) do
    {:reply, :none, {name, [], worker_pid}}
  end

  # Handle the get next message call
  @impl true
  def handle_call(:next, _from, {name, [next_message | messages], worker_pid}) do
    {:reply, {:ok, next_message}, {name, messages, worker_pid}}
  end

  # Handle genserver terminate by handing it off to another node
  @impl true
  def terminate(_reason, {name, messages, worker_pid}) do
    # shutdown worker
    send(worker_pid, :shutdown)
    # Should save state in a database as items get added to really make sure we never
    # lose them but for this example we will just do a simple handoff to another node 
    # for now
    case Node.list() do
      [] ->
        # No more nodes so just shutdown
        :ok

      nodes ->
        # call on another random node as this one might be shutting down
        :rpc.call(Enum.random(nodes), MessageQueueExample.QueueHandoff, :handoff, [name, messages])

        :ok
    end
  end
end
