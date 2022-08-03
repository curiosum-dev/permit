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
    fn pattern ->
      re = LikePatternCompiler.to_regex(pattern, [{:ignore_case, true} | ops])

      &(&1 =~ re)
    end
  end

  @impl GenOperator
  def dynamic_query(key),
    do: & dynamic([r], ilike(field(r, ^key), ^&1))
end
