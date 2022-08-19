defmodule Permit.FakeApp.Permissions do
  use Permit.Rules, actions_module: Permit.Actions.PhoenixActions

  alias Permit.FakeApp.Item

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
    |> read(Item)
  end

  def can(:moderator_1 = role) do
    grant(role)
    |> all(Item, permission_level: {:<=, 1})
  end

  def can(:moderator_2 = role) do
    grant(role)
    |> all(Item, permission_level: {{:not, :>}, 2})
  end

  def can(:thread_moderator = role) do
    grant(role)
    |> all(Item, permission_level: {:<=, 3}, thread_name: {:=~, ~r/DMT/i})
  end

  def can(role), do: grant(role)
end
