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


      defoverridable grouping_schema: 0
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
    actions_module.to_forest()
    |> Forest.traverse_forest(
      action,
      verify_fn,
      fn _ -> true end,
      fn _ -> false end,
      & Enum.all?/1
    )
  end

  @spec verify_transitively(
          module(),
          Types.controller_action(),
          (Types.controller_action() -> boolean())
        ) :: boolean()
  def verify_transitively!(actions_module, action, verify_fn) do
    case verify_transitively(actions_module, action, verify_fn) do
      {:ok, verified?} ->
        verified?
      {:error, :not_defined, action} ->
        raise UndefinedActionError, {action, actions_module}
      {:error, :cycle, trace} ->
        raise CycledDefinitionError, {trace, actions_module}
    end
  end

  def construct_query_transitively!(actions_module, key, condition_fn,  constructor_fn, join_fn) do
    with {:error, error, payload} <- construct_query_transitively(actions_module, key, condition_fn,  constructor_fn, join_fn) do
      case error do
        :not_defined ->
          raise UndefinedActionError, {payload, actions_module}
        :cycle ->
          raise CycledDefinitionError, {payload, actions_module}
      end
    end
  end

  def construct_query_transitively(actions_module, key, condition_fn,  constructor_fn, join_fn) do
    actions_module.to_forest()
    |> Forest.traverse_forest(
      key,
      condition_fn,
      constructor_fn,
      &(raise UndefinedConditionError, &1),
      join_fn,
      & elem(&1, 0)
    )|> IO.inspect(label: :QUERY)
  end
end
