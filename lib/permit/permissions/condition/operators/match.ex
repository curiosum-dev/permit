defmodule Permit.Permissions.Condition.Operators.Match do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :=~

  @impl GenOperator
  def alternatives,
    do: [:match]

  @impl GenOperator
  def semantics(ops) do
    not? = if Keyword.get(ops, :not, false) do & not &1 else & &1 end
    
    fn pattern ->
      & not?.(&1 =~ pattern)
    end
  end
end
