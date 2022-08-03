defmodule Permit.Permissions.Condition.Operators do
  @moduledoc """
     Operators
  """

  alias Permit.Permissions.Condition.Operators
  @operators [
    Operators.Eq,
    Operators.Gt,
    Operators.Ge,
    Operators.Lt,
    Operators.Le,
    Operators.Neq,
    Operators.Like,
    Operators.Ilike,
    Operators.Match,
    Operators.IsNil
  ]

  def get(operator) do
    @operators
    |> Enum.reduce_while(nil, fn op, _ ->
      if operator in [ op.symbol() | op.alternatives() ]do
        {:halt, op}
      else
        {:cont, nil}
      end
    end)
  end
end
