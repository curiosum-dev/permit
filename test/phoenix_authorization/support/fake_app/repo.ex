defmodule PhoenixAuthorization.FakeApp.Repo do
  alias PhoenixAuthorization.FakeApp.Item

  def get(Item, "1"), do: %Item{id: 1, owner_id: 1}
  def get(Item, 1), do: %Item{id: 1, owner_id: 1}
  def get(Item, "2"), do: %Item{id: 2, owner_id: 2}
  def get(Item, 2), do: %Item{id: 2, owner_id: 2}
  def get(Item, _), do: nil
end
