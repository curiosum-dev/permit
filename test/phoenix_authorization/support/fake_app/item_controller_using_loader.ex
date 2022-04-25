defmodule PhoenixAuthorization.FakeApp.ItemControllerUsingLoader do
  use Phoenix.Controller

  alias PhoenixAuthorization.FakeApp.{Authorization, Item}

  use PhoenixAuthorization.ControllerAuthorization,
    authorization_module: Authorization,
    loader_fn: &__MODULE__.load/1,
    resource_module: Item

  def index(conn, _params), do: text(conn, "listing all items")
  def show(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))

  def load(id) do
    case id do
      "1" -> %Item{id: 1, owner_id: 1}
      1 -> %Item{id: 1, owner_id: 1}
      "2" -> %Item{id: 2, owner_id: 2}
      2 -> %Item{id: 2, owner_id: 2}
      _ -> nil
    end
  end
end
