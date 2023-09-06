defmodule Permit.Operators.Ge do
  @moduledoc """
  Greater-than-or-equal operator, accessible via `:>=` and `:ge`.
  """
  alias Permit.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :>=

  @impl GenOperator
  def alternatives,
    do: [:ge]
end
