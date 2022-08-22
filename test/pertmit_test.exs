defmodule Permit.PermitTest do
  @moduledoc false
  use Permit.Case

  defmodule TestPermissions do
    @moduledoc false
    use Permit.Rules,
      actions_module: Permit.Actions.PhoenixActions
  end

  defmodule TestAuthorization do
    @moduledoc false
    use Permit,
      permissions_module: TestPermissions
  end

  describe "__using__/1" do

    test "should generate predicates" do
      Permit.Actions.PhoenixActions.list_actions()
      |> Enum.each(fn action ->
        predicate =
          action
          |> Atom.to_string()
          |> Kernel.<>("?")
          |> String.to_existing_atom()
          |> then(& {&1, 2})

        assert predicate in TestAuthorization.__info__(:functions)
      end)
    end

  end

end
