import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      DATABASE_URL is missing. For production set it, e.g.:
        export DATABASE_URL="ecto://USER:PASS@HOST/DATABASE"
      """

  config :pulse, Pulse.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end
