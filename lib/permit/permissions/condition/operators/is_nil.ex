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
  def semantics(_ops),
    do: fn _ ->
      &is_nil/1
    end

  @impl GenOperator
  def alternatives,
    do: [:nil?]

  @impl GenOperator
  def dynamic_query(key),
    do: fn _ -> dynamic([r], is_nil(field(r, ^key))) end
end
