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

  @spec get(atom()) :: {:ok, module()} | :error
  def get(operator) do
    @operators
    |> Enum.reduce_while(nil, fn op, _ ->
      if operator in [ op.symbol() | op.alternatives() ]do
        {:halt, {:ok, op}}
      else
        {:cont, :error}
      end
    end)
  end
end
