defmodule Permit.Actions do
  @moduledoc """

  """
  alias __MODULE__
  alias Permit.Actions.CycledDefinitionError
  alias Permit.Actions.Forest
  alias Permit.Actions.UndefinedActionError
  alias Permit.Permissions.UndefinedConditionError
  alias Permit.Types

  @callback grouping_schema() :: %{Types.controller_action() => [Types.action_group()]}
  @callback singular_groups() :: [Types.action_group()]

  defmacro __using__(_opts) do
    quote do
      @behaviour Actions

      def crud_grouping,
        do: %{
          create: [],
          read: [],
          update: [],
          delete: []
        }

      @impl Actions
      def grouping_schema,
        do: crud_grouping()

      @impl Actions
      def singular_groups,
        do: []

      def to_forest() do
        grouping_schema()
        |> Forest.new()
      end

      def unified_schema() do
        to_forest()
        |> Forest.to_map()
      end

      def list_actions do
        unified_schema()
        |> Map.keys()
      end

      def list_groups do
        to_forest()
        |> Forest.uniq_nodes_list()
      end

      def groups_for(action) do
        unified_schema()
        |> Map.get(action, [])
      end

      def action_defined(action) do
        unified_schema()[action]
        |> case do
          nil -> false
          _ -> true
        end
      end

      defoverridable grouping_schema: 0,
                     singular_groups: 0
    end
  end

  @spec verify_transitively(
          module(),
          Types.controller_action(),
          (Types.controller_action() -> boolean())
        ) ::
          {:ok, boolean()}
          | {:error, :cycle, [Types.action_group()]}
          | {:error, :not_defined, Types.action_group()}
  def verify_transitively(actions_module, action, verify_fn) do
    functions = [
      condition: verify_fn,
      value: fn _ -> true end,
      empty: fn _ -> false end,
      join: &Enum.all?/1
    ]

    traverse_actions(
      actions_module,
      action,
      functions
    )
  end

  @spec verify_transitively!(
          module(),
          Types.controller_action(),
          (Types.controller_action() -> boolean())
        ) :: boolean()
  def verify_transitively!(actions_module, action, verify_fn) do
    fn -> verify_transitively(actions_module, action, verify_fn) end
    |> raise_traversal_errors!(actions_module)
  end

  def traverse_actions(actions_module, key, functions) do
    actions_module.to_forest()
    |> Forest.traverse_forest(key, functions)
  end

  def traverse_actions!(actions_module, key, functions) do
    fn -> traverse_actions(actions_module, key, functions) end
    |> raise_traversal_errors!(actions_module)
  end

  defp raise_traversal_errors!(function, actions_module) do
    case function.() do
      {:ok, result} ->
        result

      {:error, :not_defined, action} ->
        raise UndefinedActionError, {action, actions_module}

      {:error, :cycle, trace} ->
        raise CycledDefinitionError, {trace, actions_module}
    end
  end
end
