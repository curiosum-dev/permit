defmodule Permit.Permissions.Condition.Operators.Like do
  @moduledoc """
     Equality Operator
  """
  alias Permit.Permissions.Condition.Operators.GenOperator
  alias Permit.Permissions.Condition.LikePatternCompiler

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :like

  @impl GenOperator
  def semantics(ops) do
    fn pattern ->
      re = LikePatternCompiler.to_regex(pattern, [{:ignore_case, false} | ops])

      &(&1 =~ re)
    end
  end

  @impl GenOperator
  def dynamic_query(key),
    do: & dynamic([r], like(field(r, ^key), ^&1))
end
