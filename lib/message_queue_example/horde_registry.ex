defmodule MessageQueueExample.HordeRegistry do
  @moduledoc """
  A Horde registry that dynamically links to the other nodes
  """
  use Horde.Registry

  @doc """
  Start the Horde Registry
  """
  def start_link(_) do
    Horde.Registry.start_link(__MODULE__, [keys: :unique], name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.Registry.init()
  end

  # Get all nodes as a module node tuple
  defp members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {__MODULE__, node} end)
  end
end
