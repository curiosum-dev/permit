defmodule Permit.Permissions.QueryConstructionTest.Resource do
  use Ecto.Schema

  schema "test_objects" do
    field(:name, :string)
    field(:foo, :integer)
    field(:bar, :integer)
  end
end

defmodule Permit.Permissions.QueryConstructionTest do
  use ExUnit.Case, async: true
  alias Permit.Permissions
  alias Permit.Permissions.QueryConstructionTest.Resource
  import Ecto.Query

  setup do
    resource = %Resource{foo: 1, bar: 2, name: "name"}

    query_convertible =
      Permissions.new()
      |> Permissions.add(:delete, Resource, foo: {:>=, 0}, bar: {{:not, :==}, 5})
      |> Permissions.add(:delete, Resource, name: nil, bar: {:not, nil})
      |> Permissions.add(:update, Resource, name: {:ilike, "%NAME"})
      |> Permissions.add(:read, Resource, foo: {:eq, 1}, name: {:not, nil})
      |> Permissions.add(:create, Resource, name: {:like, "%"}, foo: nil)

    query_convertible_nil =
      Permissions.new()
      |> Permissions.add(:delete, Resource, foo: {:>, nil}, bar: {{:not, :==}, nil})
      |> Permissions.add(:delete, Resource, name: nil, bar: {:not, nil})
      |> Permissions.add(:update, Resource, name: {:eq, nil})
      |> Permissions.add(:read, Resource, foo: {{:not, :eq}, nil}, name: {:not, nil})
      |> Permissions.add(:create, Resource, name: {:like, "%"}, foo: nil)

    query_nonconvertible =
      Permissions.new()
      |> Permissions.add(:delete, Resource, [fn _subj, res -> res.foo == 1 end])
      |> Permissions.add(:update, Resource, name: {:=~, ~r/name/i})
      |> Permissions.add(:read, Resource, [fn res -> res.foo > 0 and res.bar < 100 end])
      |> Permissions.add(:create, Resource, [fn res -> res.foo * res.bar < 10 or true end])

    %{
      resource: resource,
      convertible: query_convertible,
      convertible_nil: query_convertible_nil,
      nonconvertible: query_nonconvertible,
      actions_module: Permit.Actions.CrudActions,
      subject: nil
    }
  end

  describe "Permit.Permissions.construct_query/3" do
    test "should construct query", %{resource: res, convertible_nil: permissions, actions_module: module, subject: subject} do
      assert {:ok, _query} = Permissions.construct_query(permissions, :delete, res, subject, module)
      assert {:ok, _query} = Permissions.construct_query(permissions, :create, res, subject, module)
      assert {:ok, _query} = Permissions.construct_query(permissions, :read, res, subject, module)
      assert {:ok, _query} = Permissions.construct_query(permissions, :update, res, subject, module)
    end

    test "should not construct ecto query", %{resource: res, nonconvertible: permissions, actions_module: module, subject: subject} do
      assert {:error, condition_unconvertible: %{type: :function_2}} =
               Permissions.construct_query(permissions, :delete, res, subject, module)

      assert {:error, condition_unconvertible: _} =
               Permissions.construct_query(permissions, :update, res, subject, module)

      assert {:error, condition_unconvertible: %{type: :function_1}} =
               Permissions.construct_query(permissions, :read, res, subject, module)

      assert {:error, condition_unconvertible: %{type: :function_1}} =
               Permissions.construct_query(permissions, :create, res, subject, module)
    end

    test "should construct proper query with or", %{
        resource: res,
        convertible: permissions,
        actions_module: module,
        subject: subject
      } do
      {:ok, query} = Permissions.construct_query(permissions, :delete, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where:
                     (is_nil(r.name) and not is_nil(r.bar)) or
                     (r.foo >= ^0 and r.bar != ^5)
               )
             )
    end

    test "should construct proper query with like operator", %{
      resource: res,
      convertible: permissions,
      actions_module: module,
      subject: subject
    } do
      {:ok, query} = Permissions.construct_query(permissions, :update, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where:
                     ilike(r.name, ^"%NAME")
               )
             )
    end

    test "should construct proper query with eq and not nil", %{
      resource: res,
      convertible: permissions,
      actions_module: module,
      subject: subject
    } do
      {:ok, query} = Permissions.construct_query(permissions, :read, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where:
                     (r.foo == ^1 and not is_nil(r.name))
               )
             )
    end

    test "should construct proper query with nil", %{
        resource: res,
        convertible: permissions,
        actions_module: module,
        subject: subject
      } do
      {:ok, query} = Permissions.construct_query(permissions, :create, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where:
                     (like(r.name, ^"%") and is_nil(r.foo))
               )
             )
    end
  end

  defp compare_query(
         %Ecto.Query{from: from, wheres: [%{expr: expr, op: op, params: params}]},
         %Ecto.Query{from: from, wheres: [%{expr: expr, op: op, params: params}]}
       ),
       do: true

  defp compare_query(_, _), do: false
end
