import Config

config :ex_aws_msk_iam_auth,
  region: "us-east-2"

import_config "#{Mix.env()}.exs"
