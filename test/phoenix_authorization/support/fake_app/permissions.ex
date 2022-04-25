defmodule PhoenixAuthorization.FakeApp.Permissions do
  import PhoenixAuthorization.Rules

  alias PhoenixAuthorization.FakeApp.Item

  def can(%{role: :admin} = role) do
    grant(role)
    |> all(Item)
  end

  def can(%{role: :owner} = role) do
    grant(role)
    |> all(Item, fn user, item -> item.owner_id == user.id end)
  end

  def can(%{role: :inspector} = role) do
    grant(role)
    |> read(Item)
  end

  def can(role), do: grant(role)
end
