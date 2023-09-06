defmodule Permit.Types.ConditionTypes do
  @moduledoc """
  Contains types of conditions that can be defined in the application's permission definition module (`Permit.Permissions` or e.g. for Ecto `Permit.Ecto.Permissions`).

  Extensions like `Permit.Ecto` will typically provide their own replacements for these types.
  """

  alias Permit.Types

  # Condition types
  @type boolean_condition :: boolean()
  @type keyword_equality_condition :: {Types.struct_field(), term()}
  @type fn1_condition :: (Types.object() -> boolean())
  @type fn2_condition :: (Types.subject(), Types.object() -> boolean())

  @type condition ::
          boolean_condition()
          | keyword_equality_condition()
          | fn1_condition()
          | fn2_condition()
  @type condition_or_conditions :: condition() | [condition()]
end
