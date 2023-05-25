defmodule Permit.Permissions.Operators.In do
  @moduledoc """
     In Operator
  """
  alias Permit.Permissions.Operators.GenOperator

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
end
