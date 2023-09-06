defmodule Permit.Operators.Ilike do
  @moduledoc """
  `ILIKE` operator, accessible via `:ilike`. Semantically equivalent to matching a regular expression built
  from a SQL-like syntax (e.g. `"FOO%BAR"` pattern is equivalent to `~r/FOO.*BAR/`). Case insensitive.
  """
  alias Permit.Operators.GenOperator
  alias Permit.Operators.Ilike.PatternCompiler

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
        |> PatternCompiler.to_regex([{:ignore_case, true} | ops])

      not?.(field =~ re)
    end
  end
end
