defmodule Pulse.MixProject do
  use Mix.Project

  def project do
    [
      app: :pulse,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp releases do
    [
      pulse: [
        include_executables_for: [:unix],
        applications: [pulse: :permanent]
      ]
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
      {:bandit, "~> 1.0"},
      {:castore, "~> 1.0"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.12"},
      {:jason, "~> 1.4"},
      {:mint, "~> 1.7"},
      {:plug, "~> 1.19"},
      {:postgrex, "~> 0.19"},
      {:statistex, "~> 1.1"},
      {:typedstruct, "~> 0.5"}
    ]
  end
end
