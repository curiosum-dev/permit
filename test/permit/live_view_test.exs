defmodule Permit.LiveViewTest do
  use ExUnit.Case

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Permit.LiveViewTest.{Endpoint, HooksLive}
  alias Permit.FakeApp.{Item, User}

  @endpoint Endpoint

  describe "admin" do
    setup [:admin_role, :init_session]

    test "sets :current_user assign", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert %{current_user: %User{id: 1}} = assigns
    end

    test "can do :index on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
    end

    test "can do :edit on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1/edit")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "can do :show", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "can do :new on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/new")

      assigns = get_assigns(lv)

      assert :mounted in Map.keys(assigns)
      assert :unauthorized not in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end
  end

  describe "owner" do
    setup [:owner_role, :init_session]

    test "sets :current_user assign", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert %{current_user: %User{id: 1}} = assigns
    end

    test "can do :index on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
    end

    test "can do :show on owned item", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "cannot do :show on non-owned item", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "can do :edit on owned item", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1/edit")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "cannot do :edit on non-owned item", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/2/edit")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "can do :new on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/new")

      assigns = get_assigns(lv)

      assert :mounted in Map.keys(assigns)
      assert :unauthorized not in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end
  end

  describe "inspector" do
    setup [:inspector_role, :init_session]

    test "sets :current_user assign", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert %{current_user: %User{id: 1}} = assigns
    end

    test "can do :index on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
    end

    test "cannot do :edit", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1/edit")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "can do :show", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "cannot do :new on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/new")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end
  end

  describe "moderator_1" do
    setup [:moderator_1_role, :init_session]

    test "can do :index on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
    end

    test "can do :edit on item 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1/edit")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "can do :show on item 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "cant do :edit on item 2", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/2/edit")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "cant do :show on item 2 ", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/2")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "cant do :edit on item 3", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/3/edit")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "cant do :show on item 3", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/3")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "can do :new on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/new")

      assigns = get_assigns(lv)

      assert :mounted in Map.keys(assigns)
      assert :unauthorized not in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end
  end

  describe "moderator_2" do
    setup [:moderator_2_role, :init_session]

    test "can do :index on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
    end

    test "can do :edit on item 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1/edit")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "can do :show on item 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 1}} = assigns
    end

    test "can do :edit on item 2", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/2/edit")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 2}} = assigns
    end

    test "cant do :show on item 2 ", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/2")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 2}} = assigns
    end

    test "cant do :edit on item 3", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/3/edit")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "cant do :show on item 3", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/3")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "can do :new on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/new")

      assigns = get_assigns(lv)

      assert :mounted in Map.keys(assigns)
      assert :unauthorized not in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end
  end

  describe "thread_moderator" do
    setup [:dmt_thread_moderator_role, :init_session]

    test "can do :index on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
    end

    test "cant do :edit on item 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1/edit")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "cant do :show on item 1", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/1")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "can do :edit on item 2", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/2/edit")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 2}} = assigns
    end

    test "cant do :show on item 2 ", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/2")

      assigns = get_assigns(lv)

      assert :unauthorized not in Map.keys(assigns)
      assert %{loaded_resource: %Item{id: 2}} = assigns
    end

    test "cant do :edit on item 3", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/3/edit")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "cant do :show on item 3", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/3")

      assigns = get_assigns(lv)

      assert :unauthorized in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end

    test "can do :new on items", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items/new")

      assigns = get_assigns(lv)

      assert :mounted in Map.keys(assigns)
      assert :unauthorized not in Map.keys(assigns)
      assert :loaded_resource not in Map.keys(assigns)
    end
  end

  describe "navigation using handle_params" do
    setup [:inspector_role, :init_session]

    test "is successful, authorizes and preloads resource", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      assert :loaded_resource not in (lv |> get_assigns() |> Map.keys())

      lv |> element("#navigate_show") |> render_click()

      assert %{loaded_resource: %Item{id: 1}, loaded_resource_was_visible_in_handle_params: true} =
               get_assigns(lv)
    end

    test "delegates to unauthorized handler when unauthorized", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/items")

      lv |> element("#navigate_edit") |> render_click()

      assigns = get_assigns(lv)
      assert :loaded_resource not in (assigns |> Map.keys())
      assert %{unauthorized: true} = assigns
    end
  end

  def admin_role(context) do
    {:ok, Map.put(context, :roles, [:admin])}
  end

  def owner_role(context) do
    {:ok, Map.put(context, :roles, [:owner])}
  end

  def inspector_role(context) do
    {:ok, Map.put(context, :roles, [:inspector])}
  end

  def moderator_1_role(context) do
    {:ok, Map.put(context, :roles, [:moderator_1])}
  end

  def moderator_2_role(context) do
    {:ok, Map.put(context, :roles, [:moderator_2])}
  end

  def dmt_thread_moderator_role(context) do
    {:ok, Map.put(context, :roles, [:thread_moderator])}
  end

  def init_session(%{roles: roles}) do
    {:ok,
     conn:
       Plug.Test.init_test_session(
         build_conn(),
         %{"token" => "valid_token", roles: roles}
       )}
  end

  defp get_assigns(lv) do
    HooksLive.run(lv, fn socket -> {:reply, socket.assigns, socket} end)
  end
end
