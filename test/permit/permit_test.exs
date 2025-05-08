defmodule Permit.PermitTest do
  @moduledoc false
  use Permit.Case

  defmodule TestUser do
    defstruct [:id]
  end

  defmodule TestItem do
    defstruct [:id]
  end

  defmodule TestActions do
    use Permit.Actions

    @impl Permit.Actions
    def grouping_schema do
      %{
        a: [:create],
        b: [:read],
        c: [:delete],
        d: [:update]
      }
    end
  end

  defmodule TestPermissions do
    @moduledoc false
    use Permit.Permissions,
      actions_module: TestActions

    def can(_role), do: permit() |> a(TestItem)
  end

  defmodule TestAuthorization do
    @moduledoc false
    use Permit,
      permissions_module: Permit.PermitTest.TestPermissions
  end

  describe "__using__/1" do
    test "should generate predicates" do
      TestActions
      |> Permit.Actions.list_groups()
      |> Enum.each(fn group ->
        predicate =
          group
          |> Atom.to_string()
          |> Kernel.<>("?")
          |> String.to_existing_atom()
          |> then(&{&1, 2})

        assert predicate in TestAuthorization.__info__(:functions)
      end)
    end

    test "should delegate do?/3 to Permit.verify_record/3" do
      assert TestAuthorization.can(%TestUser{id: 1})
             |> TestAuthorization.do?(:a, TestItem)

      assert TestAuthorization.can(%TestUser{id: 1})
             |> TestAuthorization.do?(:a, %TestItem{id: 1})

      refute TestAuthorization.can(%TestUser{id: 1})
             |> TestAuthorization.do?(:b, TestItem)

      refute TestAuthorization.can(%TestUser{id: 1})
             |> TestAuthorization.do?(:b, %TestItem{id: 1})
    end
  end
end
