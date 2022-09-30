defmodule Permit.FakeApp.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:permission_level, :integer)
    field(:roles, {:array, :string})

    has_many(:item, Permit.FakeApp.Item, foreign_key: :owner_id)

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:permission_level, :roles])
  end

  defimpl Permit.HasRoles, for: Permit.FakeApp.User do
    def roles(user), do: user.roles
  end
end
