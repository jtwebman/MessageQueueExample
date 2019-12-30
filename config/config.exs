use Mix.Config

config :logger,
  level: :debug

config :libcluster,
  topologies: [
    gossip_example: [
      strategy: Elixir.Cluster.Strategy.Gossip
    ]
  ]

config :message_queue_example, port: "${PORT}"

import_config "#{Mix.env()}.exs"
