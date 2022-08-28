defmodule Permit.Actions do
  @moduledoc """

  """
  alias __MODULE__
  alias Permit.Types

  @callback grouping_schema() :: %{Types.controller_action() => [Types.action_group()]}

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

      def list_actions do
        grouping_schema()
        |> Map.keys()
      end

      def list_groups do
        grouping_schema()
        |> Map.values()
        |> List.flatten()
        |> Kernel.++(list_actions())
        |> Enum.uniq()
      end

      def groups_for(action) do
        grouping_schema()
        |> Map.get(action, [])
      end

      defoverridable grouping_schema: 0
    end
  end

  @spec traverse_actions(
      module(),
      Types.controller_action(),
      (Types.controller_action() -> any()),
      (any(), any() -> any()),
      (Enumerable.t() -> any())) ::  any()
  def traverse_actions(actions_module, starting_point, group_action_function, join_parent, join_siblings) do
    traverse_actions_with_trace(actions_module, starting_point, group_action_function, join_parent, join_siblings, [])
  end
  defp traverse_actions_with_trace(actions_module, starting_point, group_action_function, join_parent, join_siblings, trace) do
    if starting_point in trace do
      raise "Cycle detected #{inspect(trace)}"
    else
      actions_module.grouping_schema()[starting_point]
      |> case do
        nil ->
          raise "Action not defined"

        groups ->
          group_action_function.(starting_point)
          |> join_parent.(join_siblings.(
            groups
            |> Stream.map(fn action ->
              traverse_actions_with_trace(actions_module, action, group_action_function, join_parent, join_siblings, [starting_point | trace])
            end)
          ))
      end
    end
  end
end
