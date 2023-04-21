defmodule Permit.Permissions.Operators.Le do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :<=

  @impl GenOperator
  def alternatives,
    do: [:le]
end
