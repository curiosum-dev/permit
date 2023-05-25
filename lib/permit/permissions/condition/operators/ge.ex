defmodule Permit.Permissions.Operators.Ge do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :>=

  @impl GenOperator
  def alternatives,
    do: [:ge]
end
