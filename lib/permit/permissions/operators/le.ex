defmodule Permit.Operators.Le do
  @moduledoc """
  Less-than-or-equal operator, accessible via `:le`, `:<=`.
  """
  alias Permit.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :<=

  @impl GenOperator
  def alternatives,
    do: [:le]
end
