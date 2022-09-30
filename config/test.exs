import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

config :permit,
  ecto_repos: [Permit.FakeApp.Repo]

config :permit, Permit.FakeApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "permit_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Print only warnings and errors during test
config :logger, level: :warn

ExUnit.start()

# # This cleans up the test database and loads the schema
# Mix.Task.run("ecto.drop")
# Mix.Task.run("ecto.create")
# Mix.Task.run("ecto.load")

# {:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(Permit.FakeApp.Repo, :temporary)

# _ = Ecto.Adapters.Postgres.storage_down(Permit.FakeApp.Repo.config())
# :ok = Ecto.Adapters.Postgres.storage_up(Permit.FakeApp.Repo.config())

# Start a process ONLY for our test run.
# {:ok, _pid} = Permit.FakeApp.Repo.start_link

# Code.require_file("ecto_migration.exs", __DIR__)

# :ok = Ecto.Migrator.up(Permit.FakeApp.Repo, 0, Ecto.Integration.Migration, log: false)
# Ecto.Adapters.SQL.Sandbox.mode(Permit.FakeApp.Repo, :manual)
