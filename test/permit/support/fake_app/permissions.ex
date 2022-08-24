defmodule Permit.FakeApp.Permissions do
  use Permit.Rules, actions_module: Permit.Actions.PhoenixActions

  alias Permit.FakeApp.Item
  alias Permit.FakeApp.User

  def can(:admin = role) do
    grant(role)
    |> all(Item)
  end

  def can(:owner = role) do
    grant(role)
    |> all(Item, fn user, item -> item.owner_id == user.id end)
  end

  def can(:inspector = role) do
    grant(role)
    |> show(Item)
    |> read(Item)
  end

  def can(%{role: :moderator, level: 1} = role) do
    grant(role)
    |> all(Item, permission_level: {:<=, 1})
  end

  def can(%{role: :moderator, level: 2} = role) do
    grant(role)
    |> all(Item, permission_level: {{:not, :>}, 2})
  end

  def can(%{role: :thread_moderator, thread_name: thread} = role) do
    grant(role)
    |> all(Item, permission_level: {:<=, 3}, thread_name: {:=~, Regex.compile!(thread, "i")})
  end

  def can(%User{id: id} = role) do
    grant(role)
    |> all(Item, owner_id: id)
  end

  def can(role), do: grant(role)
end
