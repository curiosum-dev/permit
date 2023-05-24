defmodule Permit.AuthorizationTest do
  @moduledoc false
  use Permit.Case

  alias Permit.AuthorizationTest.Types.{TestObject, TestUser, TestUserAsRole}

  defmodule TestAuthorization do
    @moduledoc false
    use Permit,
      permissions_module: Permit.AuthorizationTest.TestPermissions
  end

  @admin_role :admin
  @operator_role :operator
  @other_user :user
  @another_one_role :another
  @alternative_role :alternative
  @like_role :like_tester
  @one_more_role :one_more

  @user_with_admin_role %TestUser{role: :admin, id: 1, overseer_id: 1}
  @user_with_operator_role %TestUser{role: :operator, id: 2, overseer_id: 1}
  @user_with_other_user %TestUser{role: :user, id: 3, overseer_id: 1}
  @user_owner %TestUserAsRole{role: :manager_bindings, id: 666, overseer_id: 1}
  @user_with_binder_role %TestUser{
    role: :binder,
    id: 1,
    overseer_id: 1100,
    some_string: "anything"
  }

  @multi_field_object_with_name %TestObject{name: "putin", field_1: 1, field_2: 3}
  @object_with_owner %TestObject{name: "object", owner_id: 666}
  @special_object %TestObject{name: "special"}
  @exceptional_object %TestObject{name: "exceptional"}
  @like_object %TestObject{name: "strange! name% with _ special characters"}
  @multi_field_object %TestObject{field_1: 1, field_2: 2}
  @multi_field_object_with_changed_field %TestObject{field_1: 1, field_2: 3}
  @multi_field_object_with_different_change %TestObject{field_1: 1, field_2: 4}
  @multi_field_object_with_one_field %TestObject{field_2: 5}
  @multi_field_object_with_other_field %TestObject{field_2: 6}
  @other_object %TestObject{}

  @cruds [:create?, :read?, :update?, :delete?]

  describe "permission granting via all/2" do
    test "should grant all permissions to admin on any object" do
      for predicate <- @cruds do
        assert apply(
                 TestAuthorization,
                 predicate,
                 [TestAuthorization.can(@admin_role), @special_object]
               )

        assert apply(
                 TestAuthorization,
                 predicate,
                 [TestAuthorization.can(@admin_role), @other_object]
               )
      end
    end

    test "should grant all permissions on object_with_owner to owner of that object" do
      assert TestAuthorization.can(@user_owner)
             |> TestAuthorization.read?(@object_with_owner)

      assert TestAuthorization.can(@user_owner)
             |> TestAuthorization.create?(@object_with_owner)

      assert TestAuthorization.can(@user_owner)
             |> TestAuthorization.update?(@object_with_owner)

      assert TestAuthorization.can(@user_owner)
             |> TestAuthorization.delete?(@object_with_owner)
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

    test "should grant permissions to another user" do
      assert TestAuthorization.can(@another_one_role)
             |> TestAuthorization.create?(@multi_field_object_with_name)

      refute TestAuthorization.can(@another_one_role)
             |> TestAuthorization.read?(@multi_field_object_with_name)

      assert TestAuthorization.can(@another_one_role)
             |> TestAuthorization.update?(@multi_field_object_with_name)

      assert TestAuthorization.can(@another_one_role)
             |> TestAuthorization.delete?(@multi_field_object_with_name)
    end

    test "should grant permissions to alternative user" do
      assert TestAuthorization.can(@alternative_role)
             |> TestAuthorization.create?(@multi_field_object_with_name)

      refute TestAuthorization.can(@alternative_role)
             |> TestAuthorization.read?(@multi_field_object_with_name)

      assert TestAuthorization.can(@alternative_role)
             |> TestAuthorization.update?(@multi_field_object_with_name)

      assert TestAuthorization.can(@alternative_role)
             |> TestAuthorization.delete?(@multi_field_object_with_name)
    end

    test "should grant permissions to like_tester" do
      assert TestAuthorization.can(@like_role)
             |> TestAuthorization.create?(@special_object)

      assert TestAuthorization.can(@like_role)
             |> TestAuthorization.read?(@exceptional_object)

      assert TestAuthorization.can(@like_role)
             |> TestAuthorization.update?(@like_object)

      assert TestAuthorization.can(@like_role)
             |> TestAuthorization.delete?(@like_object)
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

    test "should grant permissions to in operator on multi-field objects" do
      assert TestAuthorization.can(@one_more_role)
             |> TestAuthorization.update?(@multi_field_object_with_name)

      refute TestAuthorization.can(@one_more_role)
             |> TestAuthorization.create?(@multi_field_object_with_name)

      assert TestAuthorization.can(@one_more_role)
             |> TestAuthorization.read?(@multi_field_object_with_name)

      assert TestAuthorization.can(@one_more_role)
             |> TestAuthorization.delete?(@multi_field_object_with_name)
    end
  end

  describe "permission granting to subject with role" do
    test "should grant permissions to binder subject" do
      assert TestAuthorization.can(@user_with_binder_role)
             |> TestAuthorization.read?(@multi_field_object_with_name)

      assert TestAuthorization.can(@user_with_binder_role)
             |> TestAuthorization.update?(@multi_field_object_with_name)

      assert TestAuthorization.can(@user_with_binder_role)
             |> TestAuthorization.create?(@multi_field_object_with_name)

      assert TestAuthorization.can(@user_with_binder_role)
             |> TestAuthorization.delete?(@multi_field_object_with_name)
    end

    test "should grant permissions to subject with role" do
      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.read?(@exceptional_object)

      refute TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.update?(@exceptional_object)
    end

    test "should grant permissions to operator on multi-field objects" do
      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.update?(@multi_field_object)

      refute TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.update?(@multi_field_object_with_changed_field)

      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.update?(@multi_field_object_with_different_change)

      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.delete?(@multi_field_object_with_one_field)

      refute TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.delete?(@multi_field_object_with_other_field)
    end

    test "should grant all permissions to admin on any object" do
      assert TestAuthorization.can(@user_with_admin_role)
             |> TestAuthorization.create?(@special_object)

      assert TestAuthorization.can(@user_with_admin_role)
             |> TestAuthorization.read?(@other_object)

      assert TestAuthorization.can(@user_with_admin_role)
             |> TestAuthorization.update?(@special_object)

      assert TestAuthorization.can(@user_with_admin_role)
             |> TestAuthorization.delete?(@special_object)
    end

    test "should grant all permissions on special_object to special_user" do
      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.read?(@special_object)

      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.create?(@special_object)

      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.update?(@special_object)

      assert TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.delete?(@special_object)
    end

    test "should not grant permissions on other_object to special_user" do
      refute TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.read?(@other_object)

      refute TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.create?(@other_object)

      refute TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.update?(@other_object)

      refute TestAuthorization.can(@user_with_operator_role)
             |> TestAuthorization.delete?(@other_object)
    end

    test "should not grant any permissions to other_user" do
      refute TestAuthorization.can(@user_with_other_user)
             |> TestAuthorization.read?(@other_object)

      refute TestAuthorization.can(@user_with_other_user)
             |> TestAuthorization.create?(@other_object)

      refute TestAuthorization.can(@user_with_other_user)
             |> TestAuthorization.update?(@other_object)

      refute TestAuthorization.can(@user_with_other_user)
             |> TestAuthorization.delete?(@other_object)
    end
  end
end
