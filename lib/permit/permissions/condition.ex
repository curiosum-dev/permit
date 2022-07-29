defmodule Permit.Permissions.Condition do
  @moduledoc """
     Condition
  """
  @enforce_keys [:condition, :condition_type]
  defstruct [:condition, :condition_type, :semantics]

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.Condition.LikePatternCompiler

  @type(condition_type :: :const, :function_1, :function_2, :operator)
  @type t :: %Condition{
          condition: Types.condition(),
          condition_type: condition_type(),
          semantics: (any() -> boolean())
        }

  @comparison_operators_primary [
    :>,
    :>=,
    :<,
    :<=,
    :==,
    :!=
  ]
  @comparison_operators_alternative [
    :gt,
    :ge,
    :lt,
    :le,
    :eq,
    :neq
  ]

  @string_operators [:like, :ilike, :=~, :match]

  @operators @comparison_operators_primary ++
               @comparison_operators_alternative ++ @string_operators

  defp alternative_operator_mapping(:gt), do: :>
  defp alternative_operator_mapping(:ge), do: :>=
  defp alternative_operator_mapping(:lt), do: :<
  defp alternative_operator_mapping(:le), do: :<=
  defp alternative_operator_mapping(:neq), do: :!=
  defp alternative_operator_mapping(:eq), do: :==
  defp alternative_operator_mapping(:match), do: :=~
  defp alternative_operator_mapping(operator) when operator in @operators, do: operator

  defp alternative_operator_mapping(any_other),
    do: raise(ArgumentError, message: "unsupported operator #{inspect(any_other)}")

  defp interpret(operator, ops \\ [])

  defp interpret(operator, _ops)
       when operator in @comparison_operators_primary do
    fn x ->
      &apply(Kernel, operator, [&1, x])
    end
  end

  defp interpret(:=~, _ops),
    do: fn pattern ->
      &(&1 =~ pattern)
    end

  defp interpret(:ilike, ops),
    do: interpret(:like, [{:ignore_case, true} | ops])

  defp interpret(:like, ops) do
    fn pattern ->
      re = LikePatternCompiler.to_regex(pattern, ops)

      &(&1 =~ re)
    end
  end

  @spec new(Types.condition()) :: Condition.t()
  def new({key, {operator, value}})
      when operator in @operators and
             is_atom(key),
      do: new({key, {operator, value, []}})

  def new({key, {operator, value, ops}})
      when operator in @operators and
             is_atom(key) do
    operator = alternative_operator_mapping(operator)

    %Condition{
      condition: {key, {operator, value}},
      condition_type: :operator,
      semantics: interpret(operator, ops).(value)
    }
  end

  def new({key, nil})
      when is_atom(key),
      do: %Condition{
        condition: {key, {:==, nil}},
        condition_type: :operator,
        semantics: &Kernel.is_nil/1
      }

  def new({key, value})
      when is_atom(key),
      do: %Condition{
        condition: {key, {:==, value}},
        condition_type: :operator,
        semantics: &(&1 == value)
      }

  def new(true),
    do: %Condition{condition: true, condition_type: :const}

  def new(false),
    do: %Condition{condition: false, condition_type: :const}

  def new(function) when is_function(function, 1),
    do: %Condition{condition: function, condition_type: :function_1}

  def new(function) when is_function(function, 2),
    do: %Condition{condition: function, condition_type: :function_2}

  @spec satisfied?(Condition.t(), Types.resource(), Types.subject()) :: boolean()
  def satisfied?(%Condition{condition: condition, condition_type: :const}, _record, _subject),
    do: condition

  def satisfied?(
        %Condition{condition: {key, _}, condition_type: :operator, semantics: function},
        record,
        _subject
      )
      when is_struct(record) do
    record
    |> Map.get(key)
    |> then(function)
  end

  def satisfied?(%Condition{condition: condition}, module, _subject)
      when is_atom(module),
      do: !!condition

  def satisfied?(%Condition{condition: function, condition_type: :function_1}, record, _subject),
    do: !!function.(record)

  def satisfied?(%Condition{condition: function, condition_type: :function_2}, record, subject),
    do: !!function.(subject, record)
end
