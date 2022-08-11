defmodule Permit.FakeApp.Repo do
  alias Permit.FakeApp.Item

  @item1 %Item{id: 1, owner_id: 1, permission_level: 1}
  @item2 %Item{id: 2, owner_id: 2, permission_level: 2, thread_name: "dmt"}
  @item3 %Item{id: 3, owner_id: 3, permission_level: 3}

  def get(Item, "1"), do: @item1
  def get(Item, 1), do: @item1
  def get(Item, "2"), do: @item2
  def get(Item, 2), do: @item2
  def get(Item, "3"), do: @item3
  def get(Item, 3), do: @item3
  def get(Item, _), do: nil
end
