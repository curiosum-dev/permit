defmodule Permit.Operators.Match do
  @moduledoc """
  Regular expression matching operator, accessible via `:=~` and `:match`.
  """

  alias Permit.Operators.GenOperator

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
