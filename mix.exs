defmodule Pulse.MixProject do
  use Mix.Project

  def project do
    [
      app: :pulse,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Pulse.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "~> 1.0"},
      {:mint, "~> 1.7"},
      {:statistex, "~> 1.1"}
    ]
  end
end
