defmodule Permit.FakeApp.Repo.Migrations.CreateItemTable do
  use Ecto.Migration

  def change do
    create table("users") do
      add :permission_level, :integer
      add :roles, {:array, :string}, default: []

      timestamps()
    end

    create table("items") do
      add :permission_level, :integer
      add :thread_name, :string, default: ""
      add :owner_id, references("users")

      timestamps()
    end
  end
end
