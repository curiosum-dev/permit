defmodule Permit.Permissions.PermissionsActions do
  use ExUnit.Case, async: true

  defmodule TestActions do
    use Permit.Actions

    @impl Permit.Actions
    def grouping_schema do
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

  describe "__using__/1" do
    test "should generate functions" do
      TestActions.list_groups()
      |> Enum.each(fn function ->
        assert {function, 2} in TestPermissions.__info__(:functions)
        assert {function, 3} in TestPermissions.__info__(:functions)
      end)
    end

    test "should generate macros" do
      TestActions.list_groups()
      |> Enum.each(fn function ->
        assert {function, 4} in TestPermissions.__info__(:macros)
      end)
    end
  end
end
