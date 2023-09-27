defmodule Permit.Actions.Traversal do
  @moduledoc """
  Intended for usage by `Permit.Resolver` and derivatives. Traverses the tree of action definitions
  defined with `Permit.Actions` to construct a result based on a given context. The context includes:
  * the action name to be authorized
  * a function that returns a value indicating whether an authorization condition is satisfied
  * a function for the conjunction of values ("AND")
  * a function for the disjunction values ("OR")

  Depending on the intended resolution product, these functions are different.

  In `Permit`'s vanilla resolver, each record must be checked against authorization conditions
  for its inclusion in the results. Thus, the passed value function returns a boolean (based on
  whether there is permission to given action), and the conjunctor and disjunctor are `Enum.all?/1`
  and `Enum.any?/1`, respectively.

  In `Permit.Ecto` resolver, which constructs query structures based on authorization conditions,
  the values are Ecto dynamic query expressions converted from the authorization conditions,
  whereas the conjunctor joins values using SQL `AND`, and the disjunctor uses SQL `OR`.

  Part of the private API, subject to changes and not to be used on the application level.

  """
  alias Permit.Actions.Forest
  alias Permit.Types

  @doc false
  @spec traverse(
          Forest.t(),
          Types.action_group(),
          keyword(function())
        ) :: term()
  def traverse(%{forest: forest} = f, action_name, funs, trace \\ []) do
    if action_name in trace, do: throw({:cycle, [action_name | trace] |> Enum.reverse()})

    conj_function = funs[:conj]
    disj_function = funs[:disj]
    value_function = funs[:value]

    case forest[action_name] do
      # action_name can be directly checked
      # in this case, the entire trace should be verified.
      # For example, if :see implies :read implies :index,
      # then asking for :index verifies whether explicitly
      # given is the permission to :see, or :read, or :index
      [] ->
        [action_name | trace]
        |> Enum.map(value_function)
        |> disj_function.()

      # action_name cannot be directly checked
      mapped_actions when is_list(mapped_actions) ->
        mapped_actions
        |> Enum.map(&traverse(f, &1, funs, [action_name | trace]))
        |> conj_function.()

      nil ->
        throw({:not_defined, action_name})
    end
  end
end
