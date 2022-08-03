defmodule Permit.Permissions.Condition.Operators.GenOperator do
  @moduledoc """
     Generic Operator
  """
  alias __MODULE__

  @callback symbol() :: atom()
  @callback alternatives() :: [atom()]
  @callback semantics() :: (any() -> (any() -> boolean()))
  @callback semantics(keyword()) :: (any() -> (any() -> boolean()))
  @callback dynamic_query(term()) :: Ecto.Query.t()

  defmacro __using__(opts) do
    quote do
      @behaviour GenOperator
      import Ecto.Query

      def alternatives,
        do: unquote(Keyword.get(opts, :alternatives, []))

      def semantics(),
        do: semantics([])

      def semantics(_ops), do: fn x ->
        &apply(Kernel, symbol(), [&1, x])
      end

      def dynamic_query(_),
        do: nil

      defoverridable alternatives: 0,
                     semantics: 0,
                     semantics: 1,
                     dynamic_query: 1
    end
  end
end
