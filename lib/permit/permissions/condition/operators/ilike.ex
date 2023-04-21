defmodule Permit.Permissions.Operators.Ilike do
  @moduledoc """
     Ilike Operator
  """
  alias Permit.Permissions.Operators.GenOperator
  alias Permit.Permissions.ParsedCondition.LikePatternCompiler

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
end
