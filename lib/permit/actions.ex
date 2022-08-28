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
      (Enumerable.t() -> any()))
        :: {:ok, any()} |
           {:error, :cycle_in_grouping_schema_definition, [Types.action_group()]} |
           {:error, :action_not_defined, Types.action_group()}
  def traverse_actions(
    actions_module,
    starting_point,
    group_action_verifier,
    join_parent \\ &Kernel.or/2,
    join_siblings \\ &join_auxillary_groups/1) do
    try do
      traverse_actions_with_trace(actions_module, starting_point, group_action_verifier, join_parent, join_siblings, [])
      |> then(& {:ok, &1})
    catch
      action when is_atom(action) ->
        {:error, :action_not_defined, action}

      trace when is_list(trace) ->
        {:error, :cycle_in_grouping_schema_definition, trace}
    end
  end

  defp traverse_actions_with_trace(actions_module, starting_point, group_action_verifier, join_parent, join_siblings, trace) do
    if starting_point in trace do
      throw trace
    else
      actions_module.grouping_schema()[starting_point]
      |> case do
        nil ->
          throw starting_point

        groups ->
          group_action_verifier.(starting_point)
          |> join_parent.(join_siblings.(
            groups
            |> Stream.map(fn action ->
              traverse_actions_with_trace(actions_module, action, group_action_verifier, join_parent, join_siblings, [starting_point | trace])
            end)
          ))
      end
    end
  end

   defp join_auxillary_groups(groups_stream) do
    groups_stream
    |> Enum.into([])
    |> case do
      [] -> false
      groups -> Enum.all?(groups)
    end
  end
end
