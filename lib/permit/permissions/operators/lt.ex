defmodule Permit.Operators.Lt do
  @moduledoc """
  Less-than operator, accessible via `:<` and `:lt`.
  """

  alias Permit.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :<

  @impl GenOperator
  def alternatives,
    do: [:lt]
end
