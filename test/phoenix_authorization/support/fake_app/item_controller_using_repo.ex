defmodule PhoenixAuthorization.FakeApp.ItemControllerUsingRepo do
  use Phoenix.Controller

  alias PhoenixAuthorization.FakeApp.{Authorization, Item}

  use PhoenixAuthorization.ControllerAuthorization,
    authorization_module: Authorization,
    resource_module: Item,
    preload_resource_in: [:details],
    action_crud_mapping: [
      details: :read
    ],
    except: [:action_without_authorizing],
    fallback_path: "/?foo"

  def index(conn, _params), do: text(conn, "listing all items")
  def show(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))
  def edit(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))
  def details(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))
  def action_without_authorizing(conn, _params), do: text(conn, "okay")
end
