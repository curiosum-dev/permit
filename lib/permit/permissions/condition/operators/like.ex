defmodule Permit.Permissions.Condition.Operators.Like do
  @moduledoc """
     Like Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator
  alias Permit.Permissions.Condition.LikePatternCompiler

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :like

  @impl GenOperator
  def semantics(ops) do
    not? = maybe_negate(ops)

    fn pattern ->
      re = LikePatternCompiler.to_regex(pattern, [{:ignore_case, false} | ops])

      & not?.(&1 =~ re)
    end
  end

  @impl GenOperator
  def dynamic_query(key, ops) do
    if Keyword.get(ops, :not, false) do
      &dynamic([r], not like(field(r, ^key), ^&1))
    else
      &dynamic([r], like(field(r, ^key), ^&1))
    end
  end
end
