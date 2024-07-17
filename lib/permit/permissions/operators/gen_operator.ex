defmodule Permit.Operators.GenOperator do
  @moduledoc """
  Generic operator behaviour. For each operator, it allows defining:
  * the main symbol (e.g. `:==`)
  * alternative and equivalent symbols (e.g. `:eq`)
  * semantics function builders, returning functions to determine whether the operator is truthy or falsy.

  Part of the private API, subject to changes and not to be used on the application level.
  """

  alias __MODULE__

  alias Permit.Types
  alias Permit.Types.ConditionTypes

  @type operator_result :: (Types.struct_field(), Types.subject(), Types.object() -> boolean())
  @type condition_fn :: ConditionTypes.fn1_condition() | ConditionTypes.fn2_condition()

  @callback symbol() :: atom()
  @callback alternatives() :: [atom()]
  @callback semantics(condition_fn()) :: operator_result()
  @callback semantics(condition_fn(), keyword()) :: operator_result()

  defmacro __using__(_opts) do
    quote do
      @behaviour GenOperator

      defp maybe_negate(ops) do
        if Keyword.get(ops, :not, false) do
          &(not &1)
        else
          &Function.identity/1
        end
      end

      @impl true
      def alternatives, do: []

      @impl true
      def semantics(val_fn),
        do: semantics(val_fn, [])

      @impl true
      def semantics(val_fn, ops) do
        not? = maybe_negate(ops)

        fn field_val, subject, object ->
          expected_val = val_fn.(subject, object)
          op_args = [field_val, expected_val]
          arg = apply(Kernel, symbol(), op_args)

          not?.(arg)
        end
      end

      defoverridable alternatives: 0,
                     semantics: 1,
                     semantics: 2
    end
  end
end
