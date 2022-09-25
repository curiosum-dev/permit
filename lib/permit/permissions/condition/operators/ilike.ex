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
  def semantics(pattern_fn, ops) do
    not? = maybe_negate(ops)

    fn field, subject, object ->
      re =
        pattern_fn.(subject, object)
        |> LikePatternCompiler.to_regex([{:ignore_case, true} | ops])

      not?.(field =~ re)
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
