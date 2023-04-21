defmodule Permit.Permissions.Operators.Match do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :=~

  @impl GenOperator
  def alternatives,
    do: [:match]

  @impl GenOperator
  def semantics(pattern_fn, ops) do
    not? = maybe_negate(ops)

    fn field, subject, object ->
      not?.(field =~ pattern_fn.(subject, object))
    end
  end
end
