defmodule Permit.Permissions.Operators.IsNil do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :is_nil

  @impl GenOperator
  def semantics(_, ops) do
    not? = maybe_negate(ops)

    fn field, _, _ ->
      not?.(is_nil(field))
    end
  end

  @impl GenOperator
  def alternatives,
    do: [:nil?]
end
