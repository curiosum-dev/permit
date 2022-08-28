defmodule Permit.Actions.ActionsTest.Actions do

  defmodule TransitiveActions do
    use Permit.Actions

    @impl Permit.Actions
      def grouping_schema do
        %{
          change_if_field: [:read, :update],
          change_unless: [:read, :change_if_field],
          show: [:read],
          edit: [:change_unless],
          new: [:create]
        }
        |> Map.merge(crud_grouping())
      end
  end

  defmodule CyclicActions do
    use Permit.Actions

    @impl Permit.Actions
      def grouping_schema do
        %{
          change_if_field: [:read, :update, :change_unless],
          change_unless: [:read, :change_if_field],
          show: [:read],
          edit: [:change_unless]
        }
        |> Map.merge(crud_grouping())
      end
  end

  defmodule NotPresentActions do
    use Permit.Actions

    @impl Permit.Actions
      def grouping_schema do
        %{
          change_if_field: [:read, :update, :non_existent_action],
          change_unless: [:read, :change_if_field],
          show: [:read, :another_non_existent],
          edit: [:change_unless]
        }
        |> Map.merge(crud_grouping())
      end
  end
end

defmodule Permit.Actions.ActionsTest do
  use ExUnit.Case, async: true

  alias Permit.Actions
  alias Permit.Actions.{CrudActions, PhoenixActions}
  alias Permit.Actions.ActionsTest.Actions.{NotPresentActions, CyclicActions, TransitiveActions}

  describe "traverse_actions/5" do

    setup do
      orut = & &1 in [:read, :update]
      %{const_false: fn _ -> false end, only_read_update_true: orut}
    end

    test "should detect cycle", %{const_false: const_false} do
      assert {:error, :cycle_in_grouping_schema_definition, [:edit, :change_unless, :change_if_field, :change_unless]} =
        Actions.traverse_actions(CyclicActions, :edit, const_false )
      assert {:error, :cycle_in_grouping_schema_definition, [:change_unless, :change_if_field, :change_unless]} =
        Actions.traverse_actions(CyclicActions, :change_unless, const_false )
      assert {:error, :cycle_in_grouping_schema_definition, [:change_if_field, :change_unless, :change_if_field]} =
        Actions.traverse_actions(CyclicActions, :change_if_field, const_false )
    end

    test "should detect non existent groups", %{const_false: const_false} do
      assert {:error, :action_not_defined, :non_existent_action} =
        Actions.traverse_actions(NotPresentActions, :edit, const_false)
      assert {:error, :action_not_defined, :non_existent_action} =
        Actions.traverse_actions(NotPresentActions, :change_unless, const_false)
      assert {:error, :action_not_defined, :non_existent_action} =
        Actions.traverse_actions(NotPresentActions, :change_if_field, const_false)
      assert {:error, :action_not_defined, :another_non_existent} =
        Actions.traverse_actions(NotPresentActions, :show, const_false)
    end

    test "should detect non existent starting point/actions", %{const_false: const_false}  do
      for action <- [:edit, :show, :index, :new, :abc] do
        assert {:error, :action_not_defined, ^action} =
          Actions.traverse_actions(CrudActions, action, const_false)
      end
    end

    test "action access granting should be transitive", %{only_read_update_true: orut} do
      assert {:ok, true} =
        Actions.traverse_actions(TransitiveActions, :edit, orut)
      assert {:ok, true} =
        Actions.traverse_actions(TransitiveActions, :show, orut)
      assert {:ok, true} =
        Actions.traverse_actions(TransitiveActions, :read, orut)
      assert {:ok, true} =
        Actions.traverse_actions(TransitiveActions, :update, orut)
      assert {:ok, true} =
        Actions.traverse_actions(TransitiveActions, :change_unless, orut)
      assert {:ok, false} =
        Actions.traverse_actions(TransitiveActions, :delete, orut)
      assert {:ok, false} =
        Actions.traverse_actions(TransitiveActions, :create, orut)
      assert {:ok, false} =
        Actions.traverse_actions(TransitiveActions, :new, orut)
    end
  end

  describe "__using__/0" do

    setup do
      %{modules: [NotPresentActions, CyclicActions, TransitiveActions, CrudActions, PhoenixActions]}
    end

    test "every action should be in list_actions",  %{modules: mods} do
      for module <- mods do
        for action <- [:create, :read, :update, :delete] do
          assert action in module.list_actions()
        end
      end
    end

    test "every action should have a group with the same name", %{modules: mods} do
      for module <- mods do
        for action <- module.list_actions() do
          assert action in module.list_groups()
        end
      end
    end

    test "crud actions should have empty groups" do
      for action <- CrudActions.list_actions() do
        assert CrudActions.groups_for(action) == []
      end
    end
  end
end
