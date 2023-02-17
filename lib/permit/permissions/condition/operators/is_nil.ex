defmodule Permit.Permissions.Condition.Operators.IsNil do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator

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

  @impl GenOperator
  def dynamic_query(key, ops) do
    if Keyword.get(ops, :not, false) do
      fn _ -> dynamic([r], not is_nil(field(r, ^key))) end
    else
      fn _ -> dynamic([r], is_nil(field(r, ^key))) end
    end
  end
end
