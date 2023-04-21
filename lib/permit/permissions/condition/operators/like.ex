defmodule Permit.Permissions.Operators.Like do
  @moduledoc """
     Like Operator
  """
  alias Permit.Permissions.Operators.GenOperator
  alias Permit.Permissions.ParsedCondition.LikePatternCompiler

  use GenOperator

  @impl GenOperator
  def symbol,
    do: :like

  @impl GenOperator
  def semantics(pattern_fn, ops) do
    not? = maybe_negate(ops)

    fn field, subject, object ->
      re =
        pattern_fn.(subject, object)
        |> LikePatternCompiler.to_regex([{:ignore_case, false} | ops])

      not?.(field =~ re)
    end
  end
end
