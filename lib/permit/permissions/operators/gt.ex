defmodule Permit.Operators.Gt do
  @moduledoc """
  Greater-than operator, accessible via `:>` and `:gt`.
  """
  alias Permit.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :>

  @impl GenOperator
  def alternatives,
    do: [:gt]
end
