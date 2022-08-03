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

      def alternatives,
        do: unquote(Keyword.get(opts, :alternatives, []))

      def semantics(),
        do: semantics([])

      def semantics(ops) do
        not? = if Keyword.get(ops, :not, false) do & not &1 else & &1 end
        fn x ->
          & not?.(apply(Kernel, symbol(), [&1, x]))
        end

      end

      def dynamic_query(_, _),
        do: nil


      # defmacro maybe_not(ops, t, f) do
      #   if Keyword.get(unquote(ops), :not, false) do
      #     f
      #   else
      #     t
      #   end
      # end

      defoverridable alternatives: 0,
                     semantics: 0,
                     semantics: 1,
                     dynamic_query: 2
    end
  end
end
