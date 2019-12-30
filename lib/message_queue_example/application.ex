defmodule MessageQueueExample.Application do
  @moduledoc "HTTP Message Queue Example Processing 1 message per queue a second"

  use Application

  def start(_type, _args) do
    port = get_port(Application.get_env(:message_queue_example, :port))
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      {Cluster.Supervisor, [topologies, [name: MessageQueueExample.ClusterSupervisor]]},
      MessageQueueExample.QueueHandoff,
      MessageQueueExample.HordeRegistry,
      MessageQueueExample.HordeSupervisor,
      MessageQueueExample.NodeListener,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: MessageQueueExample.Endpoint,
        options: [port: port]
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MessageQueueExample.Supervisor)
  end

  # get the port from configuration defaults 4000
  defp get_port("${PORT}"), do: "PORT" |> System.get_env() |> get_port()
  defp get_port(port) when is_integer(port), do: port
  defp get_port(port) when is_bitstring(port), do: port |> Integer.parse() |> get_port()
  defp get_port({port, _}), do: port
  defp get_port(_), do: 4000
end
