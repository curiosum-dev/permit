defmodule Permit.Permissions.Condition.Operators.Match do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :=~

  @impl GenOperator
  def alternatives,
    do: [ :match ]

  @impl GenOperator
  def semantics(_ops), do: fn pattern ->
    &(&1 =~ pattern)
  end
end
