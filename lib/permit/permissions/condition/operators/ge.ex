defmodule Permit.Permissions.Condition.Operators.Ge do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :>=

  @impl GenOperator
  def alternatives,
    do: [ :ge ]

  @impl GenOperator
  def dynamic_query(key),
    do: & dynamic([r], field(r, ^key) >= ^&1)
end
