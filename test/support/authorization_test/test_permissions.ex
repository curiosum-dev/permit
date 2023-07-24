defmodule Permit.AuthorizationTest.TestPermissions do
  @moduledoc false
  use Permit.RuleSyntax

  alias Permit.AuthorizationTest.Types.{TestObject, TestUser, TestUserAsRole}

  def can(:admin = _role) do
    permit()
    |> all(TestObject)
  end

  def can(:operator = _role) do
    permit()
    |> all(TestObject, name: "special")
    |> read(TestObject, name: "exceptional")
    |> update(TestObject, field_1: 1, field_2: 2)
    |> update(TestObject, field_2: 4)
    |> delete(TestObject, field_2: 5)
    |> create(TestObject, field_2: 6)
  end

  def can(:manager = _role) do
    permit()
    |> all(TestObject, fn user, object -> object.manager_id == user.id end)
    |> all(TestUser, fn user, other_user -> other_user.overseer_id == user.id end)
  end

  def can(:manager_bindings = _role) do
    permit()
    |> all(TestObject, [user, object], manager_id: {:==, user.id})
    |> all(TestUser, [user, other_user], overseer_id: {:==, user.id})
  end

  def can(:another = _role) do
    permit()
    |> create(TestObject, field_1: {:>, 0}, field_2: {:<=, 3})
    |> read(TestObject, field_1: {:<, 1}, field_2: {:>=, 3})
    |> update(TestObject, field_1: {:!=, 2}, field_2: {:==, 3})
    |> delete(TestObject, name: {:=~, ~r/put ?in/}, name: {:=~, ~r/P.T ?I./i})
  end

  def can(:like_tester = _role) do
    permit()
    |> create(TestObject, name: {:like, "spe__a_"})
    |> read(TestObject, name: {:ilike, "%xcEpt%"})
    |> update(TestObject, name: {{:not, :like}, "speci!%", escape: "!"})
    |> delete(TestObject, name: {:like, "%!!%!%%!_%", escape: "!"})
  end

  def can(:alternative = _role) do
    permit()
    |> create(TestObject, field_1: {:gt, 0}, field_2: {:le, 3})
    |> read(TestObject, field_1: {:lt, 1}, field_2: {:ge, 3})
    |> update(TestObject, field_1: {:neq, 2}, field_2: {:eq, 3})
    |> delete(TestObject, name: {:match, ~r/put ?in/}, name: {:match, ~r/P.T ?I./i})
  end

  def can(:one_more = _role) do
    permit()
    |> update(TestObject, field_1: {:in, [1, 2, 3, 4]}, field_2: {:in, [3]})
    |> create(TestObject, field_1: {:in, [5]}, field_2: {:in, [3]})
    |> read(TestObject, field_1: {{:not, :==}, 2}, name: {{:not, :like}, "%nt%"})
    |> delete(TestObject, field_1: {{:not, :in}, [5]}, field_2: {:in, [3]})
  end

  def can(:binder = _role) do
    permit()
    |> permission_to(:read, TestObject, [s],
      field_1: s.id,
      field_2: {:<, s.overseer_id}
    )
    |> update(TestObject, [subject, obj],
      field_1: {{:not, :==}, 2},
      name: {{:not, :==}, subject.some_string}
    )
    |> create(TestObject, [_, object], field_1: {{:not, :eq}, object.field_2})
    |> delete(TestObject, [s, object],
      field_1: {{:not, :eq}, object.field_2},
      field_2: {:<, s.overseer_id}
    )
  end

  def can(%TestUserAsRole{id: id} = _role) do
    permit()
    |> all(TestObject, owner_id: id)
  end

  def can(_role), do: permit()
end
