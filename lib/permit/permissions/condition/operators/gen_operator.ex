defmodule Permit.Permissions.Condition.Operators.GenOperator do
  @moduledoc """
     Generic Operator
  """
  alias __MODULE__
  @type field_subject_object_fun :: (any(), any(), any() -> boolean())

  @callback symbol() :: atom()
  @callback alternatives() :: [atom()]
  @callback semantics(any()) :: field_subject_object_fun()
  @callback semantics(any(), keyword()) :: field_subject_object_fun()
  @callback dynamic_query(term(), keyword()) :: (any() -> Ecto.Query.DynamicExpr.t()) | nil

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

      def semantics(val_fn),
        do: semantics(val_fn, [])

      def semantics(val_fn, ops) do
        not? = maybe_negate(ops)

        fn field_val, subject, object ->
          not?.(apply(Kernel, symbol(), [field_val, val_fn.(subject, object)]))
        end
      end

      def dynamic_query(_, _),
        do: nil

      defoverridable alternatives: 0,
                     semantics: 1,
                     semantics: 2,
                     dynamic_query: 2
    end
  end
end
