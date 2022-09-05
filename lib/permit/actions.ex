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

      def unified_schema() do
        grouping_schema()
        |> Enum.map(&translate/1)
        |> Enum.into(%{})
      end

      def list_actions do
        unified_schema()
        |> Map.keys()
      end

      def list_groups do
        unified_schema()
        |> Map.values()
        |> List.flatten()
        |> Kernel.++(list_actions())
        |> Enum.uniq()
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

      def dependent_actions(action) do
        list_actions()
        |> Enum.map(fn key ->
          action in unified_schema()[key] && action
        end)
        |> Enum.filter(& &1 != nil)
      end

      defp translate({key, values} = pair)
        when is_atom(key) and is_list(values), do: pair
      defp translate({key, value})
        when is_atom(key) and is_atom(value), do: {key, [value]}
      defp translate(key)
        when is_atom(key), do: {key, []}

      defoverridable grouping_schema: 0
    end
  end

  @spec traverse_actions(
          module(),
          Types.controller_action(),
          (Types.controller_action() -> boolean())
        ) ::
          {:ok, any()}
          | {:error, :cycle_in_grouping_schema_definition, [Types.action_group()]}
          | {:error, :action_not_defined, Types.action_group()}
  def traverse_actions(actions_module, starting_point, verify) do
    try do
      traverse_with_trace(actions_module, starting_point, verify, [])
      |> then(&{:ok, &1})
    catch
      {:action_not_defined, action} ->
        {:error, :action_not_defined, action}

      {:cycle, trace} ->
        {:error, :cycle_in_grouping_schema_definition, trace}
    end
  end

  defp traverse_with_trace(module, starting_point, verify, trace) do
    cond do
      starting_point in trace ->
        throw({:cycle, Enum.reverse([starting_point | trace])})

      module.action_defined(starting_point) ->
        verify.(starting_point) or
        starting_point
        |> module.groups_for()
        |> Stream.map(fn action ->
          traverse_with_trace(module, action, verify, [starting_point | trace])
        end)
        |> join_auxillary_groups()


      true ->
        throw({:action_not_defined, starting_point})
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
