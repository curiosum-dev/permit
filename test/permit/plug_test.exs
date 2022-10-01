defmodule Permit.PlugTest do
  use ExUnit.Case, async: true
  use Permit.PlugTest.RouterHelper

  alias Permit.FakeApp.{
    Item,
    Router,
    RouterUsingLoader
  }

  describe "admin" do
    setup do
      %{conn: create_conn(Router, :post, "/sign_in", %{id: 1, roles: [:admin]})}
    end

    test "authorizes :index action", %{conn: conn} do
      conn = call(conn, :get, "/items")
      assert conn.resp_body == "listing all items"
    end

    test "authorizes :show action", %{conn: conn} do
      conn = call(conn, :get, "/items/1")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 1} = conn.assigns[:loaded_resource]
    end

    test "raises when record does not exist", %{conn: conn} do
      assert_raise Plug.Conn.WrapperError, ~r/Ecto\.NoResultsError/, fn ->
        call(conn, :get, "/items/0")
      end
    end
  end

  describe "admin, using loader function instead of repo" do
    setup do
      %{
        conn: create_conn(RouterUsingLoader, :post, "/sign_in", %{id: 1, roles: [:admin]})
      }
    end

    test "authorizes :index action", %{conn: conn} do
      conn = call(conn, :get, "/items")
      assert conn.resp_body == "listing all items"
    end

    test "authorizes :show action", %{conn: conn} do
      conn = call(conn, :get, "/items/1")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 1} = conn.assigns[:loaded_resource]
    end

    test "raises when record does not exist", %{conn: conn} do
      assert_raise Plug.Conn.WrapperError, ~r/NoResultsError/, fn ->
        call(conn, :get, "/items/0")
      end
    end
  end

  describe "user" do
    setup do
      %{conn: create_conn(Router, :post, "/sign_in", %{id: 1, roles: [:user]})}
    end

    test "does not authorize :index action", %{conn: conn} do
      conn = call(conn, :get, "/items")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :show action", %{conn: conn} do
      conn = call(conn, :get, "/items/1")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize when record does not exist", %{conn: conn} do
      conn = call(conn, :get, "/items/0")
      assert_unauthorized(conn, "/?foo")
    end

    test "skips authorization for :action_without_authorizing via :except option", %{conn: conn} do
      conn = call(conn, :get, "/action_without_authorizing")
      assert conn.resp_body =~ ~r[okay]
    end
  end

  describe "owner" do
    setup do
      %{conn: create_conn(Router, :post, "/sign_in", %{id: 1, roles: [:owner]})}
    end

    test "authorizes :index action", %{conn: conn} do
      conn = call(conn, :get, "/items")
      assert conn.resp_body == "listing all items"
    end

    test "authorizes :show action for object with matching :owner_id", %{conn: conn} do
      # conn = call(conn, :get, "/items/1")
      # assert conn.resp_body =~ ~r[Item]
      # assert [%Item{id: 1}] = conn.assigns[:loaded_resources]
      assert_raise Plug.Conn.WrapperError,
                   ~r/Permit.Permissions.UnconvertibleConditionError/,
                   fn -> call(conn, :get, "/items/1") end
    end

    test "does not authorize :show action for object without matching :owner_id", %{conn: conn} do
      # conn = call(conn, :get, "/items/2")
      # assert_unauthorized(conn, "/?foo")
      assert_raise Plug.Conn.WrapperError,
                   ~r/Permit.Permissions.UnconvertibleConditionError/,
                   fn -> call(conn, :get, "/items/2") end
    end
  end

  describe "inspector" do
    setup do
      %{conn: create_conn(Router, :post, "/sign_in", %{id: 1, roles: [:inspector]})}
    end

    test "authorizes :index action", %{conn: conn} do
      conn = call(conn, :get, "/items")
      assert conn.resp_body == "listing all items"
    end

    test "authorizes :show action", %{conn: conn} do
      conn = call(conn, :get, "/items/1")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 1} = conn.assigns[:loaded_resource]
    end

    test "authorizes :details action and preloads resource via :action_crud_mapping and :preload_resource_in options",
         %{conn: conn} do
      conn = call(conn, :get, "/details/1")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 1} = conn.assigns[:loaded_resource]
    end

    test "does not authorize :edit action", %{conn: conn} do
      conn = call(conn, :get, "/items/1/edit")
      assert_unauthorized(conn, "/?foo")
    end
  end

  describe "moderator_1" do
    setup do
      %{
        conn:
          create_conn(Router, :post, "/sign_in", %{id: 1, roles: [%{role: :moderator, level: 1}]})
      }
    end

    test "authorizes :index action", %{conn: conn} do
      conn = call(conn, :get, "/items")
      assert conn.resp_body == "listing all items"
    end

    test "authorizes :show action on item 1", %{conn: conn} do
      conn = call(conn, :get, "/items/1")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 1} = conn.assigns[:loaded_resource]
    end

    test "authorizes :edit action on item 1", %{conn: conn} do
      conn = call(conn, :get, "/items/1/edit")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 1} = conn.assigns[:loaded_resource]
    end

    test "authorizes :details action on item 1 and preloads resource via :action_crud_mapping and :preload_resource_in options",
         %{conn: conn} do
      conn = call(conn, :get, "/details/1")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 1} = conn.assigns[:loaded_resource]
    end

    test "does not authorize :details on item 2", %{conn: conn} do
      conn = call(conn, :get, "/details/2")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :show action on item 2", %{conn: conn} do
      conn = call(conn, :get, "/items/2")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :edit action on item 2", %{conn: conn} do
      conn = call(conn, :get, "/items/2/edit")
      assert_unauthorized(conn, "/?foo")
    end
  end

  describe "thread_moderator" do
    setup do
      %{
        conn:
          create_conn(Router, :post, "/sign_in", %{
            id: 1,
            roles: [%{role: :thread_moderator, thread_name: "dmt"}]
          })
      }
    end

    test "authorizes :index action", %{conn: conn} do
      conn = call(conn, :get, "/items")
      assert conn.resp_body == "listing all items"
    end

    test "authorizes :show action on item 2", %{conn: conn} do
      conn = call(conn, :get, "/items/2")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 2} = conn.assigns[:loaded_resource]
    end

    test "authorizes :edit action on item 2", %{conn: conn} do
      conn = call(conn, :get, "/items/2/edit")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 2} = conn.assigns[:loaded_resource]
    end

    test "authorizes :details action on item 2 and preloads resource via :action_crud_mapping and :preload_resource_in options",
         %{conn: conn} do
      conn = call(conn, :get, "/details/2")
      assert conn.resp_body =~ ~r[Item]
      assert %Item{id: 2} = conn.assigns[:loaded_resource]
    end

    test "does not authorize :details on item 1", %{conn: conn} do
      conn = call(conn, :get, "/details/1")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :show action on item 1", %{conn: conn} do
      conn = call(conn, :get, "/items/1")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :edit action on item 1", %{conn: conn} do
      conn = call(conn, :get, "/items/1/edit")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :details on item 3", %{conn: conn} do
      conn = call(conn, :get, "/details/3")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :show action on item 3", %{conn: conn} do
      conn = call(conn, :get, "/items/3")
      assert_unauthorized(conn, "/?foo")
    end

    test "does not authorize :edit action on item 3", %{conn: conn} do
      conn = call(conn, :get, "/items/3/edit")
      assert_unauthorized(conn, "/?foo")
    end
  end

  defp assert_unauthorized(conn, fallback_path) do
    assert conn.private.phoenix_flash["error"]
    assert Map.new(conn.resp_headers)["location"] == fallback_path
  end

  defp create_conn(router, verb, path, params) do
    router
    |> call(verb, path, params)
    |> Map.put(:secret_key_base, secret_key_base())
  end

  defp secret_key_base do
    :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64)
  end
end
