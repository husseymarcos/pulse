Application.ensure_all_started(:pulse)
_ = Ecto.Migrator.run(Pulse.Repo, :up, all: true)
ExUnit.start()
