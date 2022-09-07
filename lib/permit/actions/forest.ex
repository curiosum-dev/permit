defmodule Permit.Actions.Forest do
  @enforce_keys [:forest]
  defstruct [:forest]
  @moduledoc """

  """
  alias __MODULE__
  @type vertex :: atom()
  @type t :: %Forest{forest: %{vertex() => [vertex()]}}

  def new(list_or_map) when is_list(list_or_map) or is_map(list_or_map) do
    list_or_map
    |> Enum.map(&translate/1)
    |> Enum.into(%{})
    |> then(& %Forest{forest: &1})
  end

  def uniq_nodes_list(%Forest{forest: forest}) do
    forest
    |> Map.values()
    |> List.flatten()
    |> Kernel.++(Map.keys(forest))
    |> Enum.uniq()
  end

  def to_map(%Forest{forest: map}),
    do: map

  defp translate({key, values} = pair)
    when is_atom(key) and is_list(values), do: pair
  defp translate({key, value})
    when is_atom(key) and is_atom(value), do: {key, [value]}
  defp translate(key)
    when is_atom(key), do: {key, []}

  @spec traverse_forest(
    Permit.Actions.Forest.t(),
    any(),
    (any() -> boolean()),
    (any() -> term()),
    (any() -> term()),
    ([term()] -> term()),
    (any() -> vertex())) ::
          {:ok, term()} | {:error, :cycle | :not_defined, term()}
  def traverse_forest(%Forest{forest: forest}, value, condition, value_action, empty_action, join_action, node_for_value \\ & &1) do
    try do
      traverse_aux(forest, value, condition, value_action, empty_action, join_action, node_for_value, [])
      |> then(&{:ok, &1})
    catch
      {:not_defined, val} ->
        {:error, :not_defined, val}

      {:cycle, trace} ->
        {:error, :cycle, trace}
    end
  end

  defp traverse_aux(forest, value, condition, value_action, empty_action, join_action, node_for_value, trace) do
    cond do
      value in trace ->
        throw({:cycle, Enum.reverse([value | trace])})

      condition.(value) ->
        value_action.(value)

      [] = forest[node_for_value.(value)] ->
        empty_action.(value)

      nil = forest[node_for_value.(value)] ->
        throw({:not_defined, value})

      true -> forest[node_for_value.(value)]
        |> Enum.map(
          &traverse_aux(forest, &1, condition, value_action, empty_action, join_action, node_for_value, [value | trace])
        )
        |> join_action.()
    end
  end
end
