defmodule Permit.Operators.Eq do
  @moduledoc """
  Equality operator, accessible via `:==` and `:eq`.
  """

  alias Permit.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :==

  @impl GenOperator
  def alternatives,
    do: [:eq]
end
