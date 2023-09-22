defmodule Permit.Actions.Forest do
  @moduledoc ~S"""
  Encapsulates the directed acyclic graph built from permissions defined using `Permit.Permissions` and provides traversal functions.

  Part of the private API, subject to changes and not to be used on the application level.
  """

  @enforce_keys [:forest]
  defstruct [:forest]

  alias __MODULE__
  @type vertex :: atom()
  @type t :: %Forest{forest: %{vertex() => [vertex()]}}

  @doc false
  def new(list_or_map) when is_list(list_or_map) or is_map(list_or_map) do
    list_or_map
    |> Enum.map(&translate/1)
    |> Enum.into(%{})
    |> then(&%Forest{forest: &1})
  end

  @doc false
  def uniq_nodes_list(%Forest{forest: forest}) do
    forest
    |> Map.values()
    |> List.flatten()
    |> Kernel.++(Map.keys(forest))
    |> Enum.uniq()
  end

  @doc false
  def to_map(%Forest{forest: map}),
    do: map

  defp translate({key, values} = pair)
       when is_atom(key) and is_list(values),
       do: pair

  defp translate({key, value})
       when is_atom(key) and is_atom(value),
       do: {key, [value]}

  defp translate(key)
       when is_atom(key),
       do: {key, []}

  @doc false
  @spec traverse_forest(
          Forest.t(),
          any(),
          condition: (any() -> boolean()),
          value: (any() -> term()),
          empty: (any() -> term()),
          join: ([term()] -> term())
        ) ::
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

  defp traverse_aux(forest, action_name, actions, trace) do
    is_condition_directly_defined = Keyword.fetch!(actions, :condition)
    value_fn = Keyword.fetch!(actions, :value)
    empty_fn = Keyword.fetch!(actions, :empty)
    join_fn = Keyword.fetch!(actions, :join)

    cond do
      action_name in trace ->
        throw({:cycle, Enum.reverse([action_name | trace])})

      is_condition_directly_defined.(action_name) ->
        join_fn.([
          value_fn.(action_name),
          transitive_traversal(forest, action_name, actions, trace)
        ])

      [] == forest[action_name] ->
        empty_fn.(action_name)

      nil == forest[action_name] ->
        throw({:not_defined, action_name})

      true ->
        transitive_traversal(forest, action_name, actions, trace)
    end
  end

  defp transitive_traversal(forest, action_name, actions, trace) do
    join_fn = Keyword.fetch!(actions, :join)

    forest[action_name]
    |> Enum.map(&traverse_aux(forest, &1, actions, [action_name | trace]))
    |> join_fn.()
  end
end
