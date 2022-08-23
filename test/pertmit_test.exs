defmodule Permit.PermitTest do
  @moduledoc false
  use Permit.Case

  defmodule TestActions do
    use Permit.Actions

    @impl Permit.Actions
    def mappings do
      Map.merge(super(), %{
        a: [:create],
        b: [:read],
        c: [:delete],
        d: [:update]
      })
    end
  end

  defmodule TestPermissions do
    @moduledoc false
    use Permit.Rules,
      actions_module: TestActions
  end

  defmodule TestAuthorization do
    @moduledoc false
    use Permit,
      permissions_module: TestPermissions
  end

  describe "__using__/1" do

    test "should generate predicates" do
      TestActions.list_actions()
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
