defmodule Permit.Permissions.Operators.GenOperator do
  @moduledoc """
     Generic Operator
  """
  alias __MODULE__
  @type field_subject_object_fun :: (any(), any(), any() -> boolean())

  @callback symbol() :: atom()
  @callback alternatives() :: [atom()]
  @callback semantics(any()) :: field_subject_object_fun()
  @callback semantics(any(), keyword()) :: field_subject_object_fun()

  defmacro __using__(opts) do
    quote do
      @behaviour GenOperator

      defp maybe_negate(ops) do
        if Keyword.get(ops, :not, false) do
          &(not &1)
        else
          &Function.identity/1
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

      defoverridable alternatives: 0,
                     semantics: 1,
                     semantics: 2
    end
  end
end
