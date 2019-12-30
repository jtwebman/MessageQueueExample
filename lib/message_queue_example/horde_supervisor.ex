defmodule MessageQueueExample.HordeSupervisor do
  @moduledoc """
  A Horde dynamic supervisor that links with other nodes dynamically
  """
  use Horde.DynamicSupervisor

  @doc """
  Start the Horde DynamicSupervisor
  """
  def start_link(_) do
    Horde.DynamicSupervisor.start_link(
      __MODULE__,
      [strategy: :one_for_one],
      name: __MODULE__
    )
  end

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  # Get all nodes as a module node tuple
  defp members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {__MODULE__, node} end)
  end
end
