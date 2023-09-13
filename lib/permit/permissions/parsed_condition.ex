defmodule Permit.Permissions.ParsedCondition do
  @moduledoc """
  Represents the product of parsing a condition by a function implementing
  the `c:Permit.Permissions.can/1` callback.

  A condition parsed by Permit's rule syntax parser contains:
  * condition semantics, that is: a function that allows for checking
    whether the condition is satisfied
  * an indication of whether it is negated (i.e. a condition defined as
    `{:not, ...}`)
  * metadata (`:private`), which can be used by alternative parsers (e.g.
    `Permit.Ecto.Permissions` puts dynamic query constructors there)

  Part of the private API, subject to changes and not to be used on the
  application level.
  """

  @enforce_keys [:condition, :condition_type]
  defstruct [:condition, :condition_type, :semantics, not: false, private: %{}]

  alias __MODULE__
  alias Permit.Types
  alias Permit.Types.ConditionTypes

  require Permit.Operators

  @type condition_type :: :const | :function_1 | :function_2 | {:operator, module()}
  @type t :: %ParsedCondition{
          condition:
            ConditionTypes.boolean_condition()
            | {Types.struct_field(), (Types.subject(), Types.object() -> any())}
            | ConditionTypes.fn1_condition()
            | ConditionTypes.fn2_condition(),
          condition_type: condition_type(),
          semantics: (Types.struct_field(), Types.subject(), Types.object() -> boolean()),
          private: map(),
          not: boolean()
        }

  @doc false
  def satisfied?(
        %ParsedCondition{condition: condition, condition_type: :const},
        _record,
        _subject
      ),
      do: condition

  def satisfied?(
        %ParsedCondition{
          condition: {key, _},
          condition_type: {:operator, _},
          semantics: semantics
        },
        record,
        subject
      )
      when is_struct(record) do
    record
    |> Map.get(key)
    |> semantics.(subject, record)
  end

  def satisfied?(%ParsedCondition{condition: condition}, module, _subject)
      when is_atom(module),
      do: !!condition

  def satisfied?(
        %ParsedCondition{condition: function, condition_type: :function_1},
        record,
        _subject
      ),
      do: !!function.(record)

  def satisfied?(
        %ParsedCondition{condition: _fun, condition_type: :function_2},
        _record,
        subject
      )
      when is_nil(subject),
      do:
        raise(
          "Unable to use function/2 condition feature without subject. First argument of this function is nonexisting subject"
        )

  def satisfied?(
        %ParsedCondition{condition: function, condition_type: :function_2},
        record,
        subject
      ),
      do: !!function.(subject, record)
end
