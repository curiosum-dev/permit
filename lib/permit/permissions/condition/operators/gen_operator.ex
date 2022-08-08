defmodule Permit.Permissions.Condition.Operators.GenOperator do
  @moduledoc """
     Generic Operator
  """
  alias __MODULE__

  @callback symbol() :: atom()
  @callback alternatives() :: [atom()]
  @callback semantics() :: (any() -> (any() -> boolean()))
  @callback semantics(keyword()) :: (any() -> (any() -> boolean()))
  @callback dynamic_query(term(), keyword()) :: (any() -> Ecto.Query.DynamicExpr.t())

  defmacro __using__(opts) do
    quote do
      @behaviour GenOperator
      import Ecto.Query

      defp maybe_negate(ops) do
        if Keyword.get(ops, :not, false) do
          &(not &1)
        else
          & &1
        end
      end

      def alternatives,
        do: unquote(Keyword.get(opts, :alternatives, []))

      def semantics(),
        do: semantics([])

      def semantics(ops) do
        not? = maybe_negate(ops)

        fn x ->
          &not?.(apply(Kernel, symbol(), [&1, x]))
        end
      end

      def dynamic_query(_, _),
        do: nil

      defoverridable alternatives: 0,
                     semantics: 0,
                     semantics: 1,
                     dynamic_query: 2
    end
  end
end
