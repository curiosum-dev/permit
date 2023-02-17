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

  defp maybe_not(x, false),
    do: x

  defp maybe_not(x, true),
    do: not x

  @impl GenOperator
  def semantics(val_fn, ops) do
    fn field, subject, object ->
      field
      |> Kernel.in(val_fn.(subject, object))
      |> maybe_not(Keyword.get(ops, :not, false))
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
