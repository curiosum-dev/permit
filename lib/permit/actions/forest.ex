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
end
