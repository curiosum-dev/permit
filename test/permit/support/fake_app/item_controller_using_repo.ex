defmodule Permit.FakeApp.ItemControllerUsingRepo do
  use Phoenix.Controller

  alias Permit.FakeApp.{Authorization, Item}

  use Permit.ControllerAuthorization,
    authorization_module: Authorization,
    resource_module: Item,
    preload_resource_in: [:show],
    except: [:action_without_authorizing],
    fallback_path: "/?foo"

  def index(conn, _params), do: text(conn, "listing all items")
  def show(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))
  def edit(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))
  def details(conn, _params), do: text(conn, inspect(conn.assigns[:loaded_resource]))
  def action_without_authorizing(conn, _params), do: text(conn, "okay")
end
