defmodule Permit.Permissions.Condition.Operators.Ilike do
  @moduledoc """
     Ilike Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator
  alias Permit.Permissions.Condition.LikePatternCompiler

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :ilike

  @impl GenOperator
  def semantics(ops) do
    not? = if Keyword.get(ops, :not, false) do & not &1 else & &1 end

    fn pattern ->
      re = LikePatternCompiler.to_regex(pattern, [{:ignore_case, true} | ops])

      & not?.(&1 =~ re)
    end
  end

  @impl GenOperator
  def dynamic_query(key, ops) do
    if Keyword.get(ops, :not, false) do
      &dynamic([r], not ilike(field(r, ^key), ^&1))
    else
      &dynamic([r], ilike(field(r, ^key), ^&1))
    end
  end
end
