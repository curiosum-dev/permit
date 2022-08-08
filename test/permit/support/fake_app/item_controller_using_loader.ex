defmodule Permit.FakeApp.ItemControllerUsingLoader do
  use Phoenix.Controller

  alias Permit.FakeApp.{Authorization, Item}

  use Permit.ControllerAuthorization,
    authorization_module: Authorization,
    loader_fn: &__MODULE__.load/1,
    resource_module: Item

  def index(conn, _params), do: text(conn, "listing all items")
  def show(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))

  @item1 %Item{id: 1, owner_id: 1, permission_level: 1}
  @item2 %Item{id: 2, owner_id: 2, permission_level: 2}
  @item3 %Item{id: 3, owner_id: 3, permission_level: 3}

  def load("1"), do: @item1
  def load(1), do: @item1
  def load("2"), do: @item2
  def load(2), do: @item2
  def load("3"), do: @item3
  def load(3), do: @item3
  def load(_), do: nil
end
