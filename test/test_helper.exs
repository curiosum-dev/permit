ExUnit.start()
Application.ensure_all_started(:phoenix_live_view)

Application.put_env(
  :ecto,
  Permit.FakeApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL", "ecto://localhost/ecto_network_test"),
  pool: Ecto.Adapters.SQL.Sandbox
)

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(Permit.FakeApp.Repo, :temporary)

# _ = Ecto.Adapters.Postgres.storage_down(Permit.FakeApp.Repo.config())
# :ok = Ecto.Adapters.Postgres.storage_up(Permit.FakeApp.Repo.config())

{:ok, _pid} = Permit.FakeApp.Repo.start_link()

# Code.require_file("ecto_migration.exs", __DIR__)

# :ok = Ecto.Migrator.up(Permit.FakeApp.Repo, 0, Ecto.Integration.Migration, log: false)
Process.flag(:trap_exit, true)
