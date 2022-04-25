defmodule PhoenixAuthorization.AuthorizationTest.Types do
  defmodule TestUser do
    @moduledoc false
    @behaviour PhoenixAuthorization.HasRoles

    defstruct [:id, :role, :overseer_id]

    @impl PhoenixAuthorization.HasRoles
    def roles(user), do: [user.role]
  end

  defmodule TestObject do
    @moduledoc false
    defstruct [:name, :manager_id, :field_1, :field_2]
  end
end

defmodule PhoenixAuthorization.AuthorizationTest do
  @moduledoc false
  use PhoenixAuthorization.Case

  alias PhoenixAuthorization.AuthorizationTest.Types.{TestObject, TestUser}

  defmodule TestPermissions do
    @moduledoc false
    import PhoenixAuthorization.Rules

    def can(%{role: :admin} = role) do
      grant(role)
      |> all(TestObject)
    end

    def can(%{role: :operator} = role) do
      grant(role)
      |> all(TestObject, name: "special")
      |> read(TestObject, name: "exceptional")
      |> update(TestObject, field_1: 1, field_2: 2)
      |> update(TestObject, field_2: 4)
      |> delete(TestObject, field_2: 5)
      |> create(TestObject, field_2: 6)
    end

    def can(%{role: :manager} = role) do
      grant(role)
      |> all(TestObject, fn user, object -> object.manager_id == user.id end)
      |> all(TestUser, fn user, other_user -> other_user.overseer_id == user.id end)
    end

    def can(role), do: grant(role)
  end

  defmodule TestAuthorization do
    @moduledoc false
    use PhoenixAuthorization,
      permissions_module: TestPermissions
  end

  @admin_role %{role: :admin}
  @operator_role %{role: :operator}
  @other_user %{role: :user}

  @special_object %TestObject{name: "special"}
  @exceptional_object %TestObject{name: "exceptional"}
  @multi_field_object %TestObject{field_1: 1, field_2: 2}
  @multi_field_object_with_changed_field %TestObject{field_1: 1, field_2: 3}
  @multi_field_object_with_different_change %TestObject{field_1: 1, field_2: 4}
  @multi_field_object_with_one_field %TestObject{field_2: 5}
  @multi_field_object_with_other_field %TestObject{field_2: 6}
  @other_object %TestObject{}

  describe "permission granting via all/2" do
    test "should grant all permissions to admin on any object" do
      assert TestAuthorization.can(@admin_role)
             |> TestAuthorization.create?(@special_object)

      assert TestAuthorization.can(@admin_role)
             |> TestAuthorization.read?(@other_object)

      assert TestAuthorization.can(@admin_role)
             |> TestAuthorization.update?(@special_object)

      assert TestAuthorization.can(@admin_role)
             |> TestAuthorization.delete?(@special_object)

      # checks via symbol should also be possible
      assert TestAuthorization.can(%{role: :admin})
             |> TestAuthorization.delete?(@special_object)
    end

    test "should grant all permissions on special_object to special_user" do
      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.read?(@special_object)

      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.create?(@special_object)

      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.update?(@special_object)

      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.delete?(@special_object)
    end

    test "should not grant permissions on other_object to special_user" do
      refute TestAuthorization.can(@operator_role)
             |> TestAuthorization.read?(@other_object)

      refute TestAuthorization.can(@operator_role)
             |> TestAuthorization.create?(@other_object)

      refute TestAuthorization.can(@operator_role)
             |> TestAuthorization.update?(@other_object)

      refute TestAuthorization.can(@operator_role)
             |> TestAuthorization.delete?(@other_object)
    end

    test "should not grant any permissions to other_user" do
      refute TestAuthorization.can(@other_user)
             |> TestAuthorization.read?(@other_object)

      refute TestAuthorization.can(@other_user)
             |> TestAuthorization.create?(@other_object)

      refute TestAuthorization.can(@other_user)
             |> TestAuthorization.update?(@other_object)

      refute TestAuthorization.can(@other_user)
             |> TestAuthorization.delete?(@other_object)
    end
  end

  describe "permission granting via other functions" do
    test "should grant some permissions on exceptional_object to operator" do
      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.read?(@exceptional_object)

      refute TestAuthorization.can(@operator_role)
             |> TestAuthorization.update?(@exceptional_object)
    end

    test "should grant permissions to operator on multi-field objects" do
      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.update?(@multi_field_object)

      refute TestAuthorization.can(@operator_role)
             |> TestAuthorization.update?(@multi_field_object_with_changed_field)

      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.update?(@multi_field_object_with_different_change)

      assert TestAuthorization.can(@operator_role)
             |> TestAuthorization.delete?(@multi_field_object_with_one_field)

      refute TestAuthorization.can(@operator_role)
             |> TestAuthorization.delete?(@multi_field_object_with_other_field)
    end
  end
end
