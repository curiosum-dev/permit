defmodule Permit.Operators.Neq do
  @moduledoc """
  Not-equal operator, accessible via `:!=` and `:neq`.
  """

  alias Permit.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :!=

  @impl GenOperator
  def alternatives,
    do: [:neq]
end
