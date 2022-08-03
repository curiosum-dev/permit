defmodule Permit.AuthorizationTest.Types do
  defmodule TestUser do
    @moduledoc false
    @behaviour Permit.HasRoles

    defstruct [:id, :role, :overseer_id]

    @impl Permit.HasRoles
    def roles(user), do: [user.role]
  end

  defmodule TestObject do
    @moduledoc false
    use Ecto.Schema

    schema "test_objects" do
      field(:name, :string)
      field(:manager_id, :integer, default: 0)
      field(:field_1, :integer)
      field(:field_2, :integer)
    end
  end
end

defmodule Permit.AuthorizationTest do
  @moduledoc false
  use Permit.Case

  alias Permit.AuthorizationTest.Types.{TestObject, TestUser}

  defmodule TestPermissions do
    @moduledoc false
    import Permit.Rules

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

    def can(%{role: :another} = role) do
      grant(role)
      |> create(TestObject, field_1: {:>, 0}, field_2: {:<=, 3})
      |> read(TestObject, field_1: {:<, 1}, field_2: {:>=, 3})
      |> update(TestObject, field_1: {:!=, 2}, field_2: {:==, 3})
      |> delete(TestObject, name: {:=~, ~r/put ?in/}, name: {:=~, ~r/P.T ?I./i})
    end

    def can(%{role: :like_tester} = role) do
      grant(role)
      |> create(TestObject, name: {:like, "spe__a_"})
      |> read(TestObject, name: {:ilike, "%xcEpt%"})
      |> update(TestObject, name: {:like, "speci!%", escape: "!"})
      |> delete(TestObject, name: {:like, "%!!%!%%!_%", escape: "!"})
    end

    def can(%{role: :alternative} = role) do
      grant(role)
      |> create(TestObject, field_1: {:gt, 0}, field_2: {:le, 3})
      |> read(TestObject, field_1: {:lt, 1}, field_2: {:ge, 3})
      |> update(TestObject, field_1: {:neq, 2}, field_2: {:eq, 3})
      |> delete(TestObject, name: {:match, ~r/put ?in/}, name: {:match, ~r/P.T ?I./i})
    end

    def can(%{role: :one_more} = role) do
      grant(role)
      |> update(TestObject, field_1: {:in, [1,2,3,4]}, field_2: {:in, [3]})
      |> create(TestObject, field_1: {:in, [5]}, field_2: {:in, [3]})
      |> read(TestObject, field_1: {{:not, :==}, 2}, name: {{:not, :like}, "%nt%"})
      |> delete(TestObject, field_1: {{:not, :in}, [5]}, field_2: {:in, [3]})

    end

    def can(role), do: grant(role)
  end

  defmodule TestAuthorization do
    @moduledoc false
    use Permit,
      permissions_module: TestPermissions
  end

  @admin_role %{role: :admin}
  @operator_role %{role: :operator}
  @other_user %{role: :user}
  @another_one_role %{role: :another}
  @alternative_role %{role: :alternative}
  @like_role %{role: :like_tester}
  @one_more_role %{role: :one_more}

  @special_object %TestObject{name: "special"}
  @exceptional_object %TestObject{name: "exceptional"}
  @like_object %TestObject{name: "strange! name% with _ special characters"}
  @multi_field_object %TestObject{field_1: 1, field_2: 2}
  @multi_field_object_with_changed_field %TestObject{field_1: 1, field_2: 3}
  @multi_field_object_with_different_change %TestObject{field_1: 1, field_2: 4}
  @multi_field_object_with_one_field %TestObject{field_2: 5}
  @multi_field_object_with_other_field %TestObject{field_2: 6}
  @other_object %TestObject{}
  @multi_field_object_with_name %TestObject{name: "putin", field_1: 1, field_2: 3}

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

      refute TestAuthorization.can(@like_role)
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

  describe "ecto query construction" do
    test "should construct ecto query" do
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :delete, @like_object)
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :create, @like_object)
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :read, @like_object)
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :update, @like_object)
    end

    test "should not construct ecto query" do
      assert {:error, condition_unconvertible: _, condition_unconvertible: _} =
               TestAuthorization.accessible_by(@another_one_role, :delete, @like_object)
    end
  end
end
