defmodule ExAwsMskIamAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_aws_msk_iam_auth,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway_kafka, "~> 0.3.5"},
      {:aws_signature, "~> 0.3.0"},
      {:jason, "~> 1.3"},
      {:hammox, "~> 0.5", only: :test}
    ]
  end
end
