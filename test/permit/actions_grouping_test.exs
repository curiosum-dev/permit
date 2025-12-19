defmodule Permit.ActionsGroupingTest do
  @moduledoc """
  Tests for transitive action grouping verification.

  When an action depends on other permissions (e.g., show: [:read]),
  the authorization check should verify if the required permissions are granted.
  """
  use ExUnit.Case, async: true

  defmodule Article do
    defstruct [:id, :author_id, :title]
  end

  defmodule User do
    defstruct [:id, :role]
  end

  defmodule TestActions do
    use Permit.Actions

    @impl Permit.Actions
    def grouping_schema do
      Map.merge(crud_grouping(), %{
        # Phoenix-style actions that depend on CRUD permissions
        index: [:read],
        show: [:read],
        edit: [:update],
        new: [:create]
      })
    end
  end

  defmodule TestPermissions do
    use Permit.Permissions, actions_module: TestActions

    def can(%User{role: :admin}) do
      permit()
      |> all(Article)
    end

    def can(%User{id: user_id}) do
      permit()
      |> read(Article)
      |> update(Article, author_id: user_id)
    end

    def can(_), do: permit()
  end

  defmodule TestAuthorization do
    use Permit, permissions_module: TestPermissions
  end

  describe "transitive action grouping" do
    test "show? returns true when user has :read permission and show: [:read]" do
      user = %User{id: 1}
      article = %Article{id: 1, author_id: 1, title: "Test"}

      # User has :read permission, show action requires :read
      assert TestAuthorization.can(user) |> TestAuthorization.show?(article)
    end

    test "index? returns true when user has :read permission and index: [:read]" do
      user = %User{id: 1}

      # User has :read permission, index action requires :read
      assert TestAuthorization.can(user) |> TestAuthorization.index?(Article)
    end

    test "edit? returns true when user has :update permission on their own article and edit: [:update]" do
      user = %User{id: 1}
      article = %Article{id: 1, author_id: 1, title: "Test"}

      # User has :update permission on their own articles, edit action requires :update
      assert TestAuthorization.can(user) |> TestAuthorization.edit?(article)
    end

    test "edit? returns false when user tries to edit someone else's article" do
      user = %User{id: 1}
      article = %Article{id: 2, author_id: 2, title: "Test"}

      # User doesn't have :update permission on other's articles
      refute TestAuthorization.can(user) |> TestAuthorization.edit?(article)
    end

    test "new? returns false when user only has :read permission and new: [:create]" do
      user = %User{id: 1}

      # User only has :read permission, new action requires :create
      refute TestAuthorization.can(user) |> TestAuthorization.new?(Article)
    end

    test "admin has all permissions including derived actions" do
      admin = %User{role: :admin}
      article = %Article{id: 1, author_id: 2, title: "Test"}

      # Admin has all permissions
      assert TestAuthorization.can(admin) |> TestAuthorization.show?(article)
      assert TestAuthorization.can(admin) |> TestAuthorization.index?(Article)
      assert TestAuthorization.can(admin) |> TestAuthorization.edit?(article)
      assert TestAuthorization.can(admin) |> TestAuthorization.new?(Article)
    end

    test "direct permission check still works (read?)" do
      user = %User{id: 1}
      article = %Article{id: 1, author_id: 1, title: "Test"}

      # Direct :read permission check
      assert TestAuthorization.can(user) |> TestAuthorization.read?(article)
    end

    test "direct permission check for unpermitted action (delete?)" do
      user = %User{id: 1}
      article = %Article{id: 1, author_id: 1, title: "Test"}

      # User doesn't have :delete permission
      refute TestAuthorization.can(user) |> TestAuthorization.delete?(article)
    end
  end

  describe "nested action grouping" do
    defmodule NestedActions do
      use Permit.Actions

      @impl Permit.Actions
      def grouping_schema do
        %{
          base: [],
          level1: [:base],
          level2: [:level1],
          level3: [:level2]
        }
      end
    end

    defmodule NestedPermissions do
      use Permit.Permissions, actions_module: NestedActions

      def can(:user_with_base) do
        permit()
        |> base(Article)
      end

      def can(_), do: permit()
    end

    defmodule NestedAuthorization do
      use Permit, permissions_module: NestedPermissions
    end

    test "nested action dependencies are resolved transitively" do
      # User has :base permission
      # level3 requires level2, which requires level1, which requires base
      assert NestedAuthorization.can(:user_with_base)
             |> NestedAuthorization.do?(:level3, Article)
    end
  end

  describe "dependency on multiple actions" do
    defmodule MultipleActions do
      use Permit.Actions

      @impl Permit.Actions
      def grouping_schema do
        %{
          a: [],
          b: [],
          c: [],
          d: [:a, :b, :c]
        }
      end
    end

    defmodule MultiplePermissions do
      use Permit.Permissions, actions_module: MultipleActions

      def can(:user_with_a) do
        permit()
        |> a(Article)
      end

      def can(:user_with_a_b_c) do
        permit()
        |> a(Article)
        |> b(Article)
        |> c(Article)
      end

      def can(:user_with_d) do
        permit()
        |> d(Article)
      end

      def can(_), do: permit()
    end

    defmodule MultipleAuthorization do
      use Permit, permissions_module: MultiplePermissions
    end

    test "user with a permission cannot perform d action" do
      refute MultipleAuthorization.can(:user_with_a) |> MultipleAuthorization.d?(Article)
    end

    test "user with a, b, and c permission can perform d action" do
      assert MultipleAuthorization.can(:user_with_a_b_c) |> MultipleAuthorization.d?(Article)
    end

    test "user with d permission can perform d action" do
      assert MultipleAuthorization.can(:user_with_d) |> MultipleAuthorization.d?(Article)
    end

    test "user with d permission cannot perform a action" do
      refute MultipleAuthorization.can(:user_with_d) |> MultipleAuthorization.a?(Article)
    end
  end
end
