import Config

config :pulse, Pulse.Repo,
  url: System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/pulse_test",
  pool_size: 5
