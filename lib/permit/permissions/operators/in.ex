defmodule Permit.Operators.In do
  @moduledoc """
  List inclusion operator, accessible via `:in`. Implemented using `Kernel.in/2`.
  """
  alias Permit.Operators.GenOperator

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
