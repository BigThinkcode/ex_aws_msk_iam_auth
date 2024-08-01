import Config

config :ex_aws_msk_iam_auth,
  region: "us-east-1",
  service: "kafka-cluster",
  version: "2020_10_22",
  user_agent: "msk-elixir-client",
  # 15 minutes
  ttl: 900

import_config "#{Mix.env()}.exs"
