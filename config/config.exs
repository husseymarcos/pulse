import Config

config :pulse, :http_port, 4040
config :pulse, ecto_repos: [Pulse.Repo]

config :pulse, Pulse.Repo,
  url: System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/pulse_dev",
  pool_size: 10
