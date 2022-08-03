defmodule Permit.Permissions.Condition.Operators.In do
  @moduledoc """
     In Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :in

  @impl GenOperator
  def alternatives,
    do: []

  @impl GenOperator
  def semantics(_ops),
    do: fn x ->
      & &1 in x
    end

  @impl GenOperator
  def dynamic_query(key),
    do: &dynamic([r], field(r, ^key) in ^&1)
end
