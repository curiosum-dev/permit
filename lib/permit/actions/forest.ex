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
    Forest.t(),
    any(),
    [ condition: (any() -> boolean()),
      value: (any() -> term()),
      empty: (any() -> term()),
      join: ([term()] -> term())
    ]) ::
          {:ok, term()} | {:error, :cycle | :not_defined, term()}
  def traverse_forest(%Forest{forest: forest}, value, actions) do
    try do
      traverse_aux(forest, value, actions, [])
      |> then(&{:ok, &1})
    catch
      {:not_defined, val} ->
        {:error, :not_defined, val}

      {:cycle, trace} ->
        {:error, :cycle, trace}
    end
  end

  defp traverse_aux(forest, value, actions, trace) do
    condition_fn = Keyword.fetch!(actions, :condition)
    value_fn = Keyword.fetch!(actions, :value)
    empty_fn = Keyword.fetch!(actions, :empty)
    join_fn = Keyword.fetch!(actions, :join)

    cond do
      value in trace ->
        throw({:cycle, Enum.reverse([value | trace])})

      condition_fn.(value) ->
        value_fn.(value)

      [] == forest[value] ->
        empty_fn.(value)

      nil == forest[value] ->
        throw({:not_defined, value})

      true ->
        forest[value]
        |> Enum.map(& traverse_aux(forest, &1, actions, [value | trace]))
        |> join_fn.()
    end
  end
end
