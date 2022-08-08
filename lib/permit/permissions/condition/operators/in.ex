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
  def semantics(ops) do
    case Keyword.get(ops, :not, false) do
      true ->
        fn x ->
          &(&1 not in x)
        end

      false ->
        fn x ->
          &(&1 in x)
        end
    end
  end

  @impl GenOperator
  def dynamic_query(key, ops) do
    if Keyword.get(ops, :not, false) do
      &dynamic([r], field(r, ^key) not in ^&1)
    else
      &dynamic([r], field(r, ^key) in ^&1)
    end
  end
end
