defmodule Permit.Permissions.Condition do
  @moduledoc """
     Condition
  """
  @enforce_keys [:condition, :condition_type]
  defstruct [:condition, :condition_type, :semantics]

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.Condition.Operators
  import Ecto.Query

  @type condition_type :: :const | :function_1 | :function_2 | {:operator, module()}
  @type t :: %Condition{
          condition: Types.condition(),
          condition_type: condition_type(),
          semantics: (any() -> boolean())
        }

  # @comparison_operators_primary [
  #   :>,
  #   :>=,
  #   :<,
  #   :<=,
  #   :==,
  #   :!=
  # ]
  # @comparison_operators_alternative [
  #   :gt,
  #   :ge,
  #   :lt,
  #   :le,
  #   :eq,
  #   :neq
  # ]

  # @unconvertible_operators [ :=~ ]

  # @string_operators [:like, :ilike, :=~, :match]

  # @operators @comparison_operators_primary ++
  #              @comparison_operators_alternative ++ @string_operators

  # defp alternative_operator_mapping(:gt), do: :>
  # defp alternative_operator_mapping(:ge), do: :>=
  # defp alternative_operator_mapping(:lt), do: :<
  # defp alternative_operator_mapping(:le), do: :<=
  # defp alternative_operator_mapping(:neq), do: :!=
  # defp alternative_operator_mapping(:eq), do: :==
  # defp alternative_operator_mapping(:match), do: :=~
  # defp alternative_operator_mapping(operator) when operator in @operators, do: operator

  # defp alternative_operator_mapping(any_other),
  #   do: raise(ArgumentError, message: "unsupported operator #{inspect(any_other)}")

  # defp interpret(operator, ops \\ [])

  # defp interpret(operator, _ops)
  #      when operator in @comparison_operators_primary do
  #   fn x ->
  #     &apply(Kernel, operator, [&1, x])
  #   end
  # end

  # defp interpret(:=~, _ops),
  #   do: fn pattern ->
  #     &(&1 =~ pattern)
  #   end

  # defp interpret(:ilike, ops),
  #   do: interpret(:like, [{:ignore_case, true} | ops])

  # defp interpret(:like, ops) do
  #   fn pattern ->
  #     re = LikePatternCompiler.to_regex(pattern, ops)

  #     &(&1 =~ re)
  #   end
  # end

  @spec new(Types.condition()) :: Condition.t()
  def new({key, {operator, value}})
    when is_atom(operator) and is_atom(key),
      do: new({key, {operator, value, []}})

  def new({key, {operator, value, ops}})
      when is_atom(key) do
    case Operators.get(operator) do
      module when is_atom(module) ->
        %Condition{
          condition: {key, {operator, value, ops}},
          condition_type: {:operator, module},
          semantics: module.semantics(ops).(value)
        }

      nil ->
        raise "Unsupported operator #{inspect(operator)}"
    end
  end

  def new({key, nil})
    when is_atom(key) do
      operator = Operators.get(:is_nil)

      %Condition{
        condition: {key, nil},
        condition_type: {:operator, operator},
        semantics: operator.semantics().(nil)
      }
    end

  def new({key, value})
    when is_atom(key) do
      operator = Operators.get(:==)

      %Condition{
        condition: {key, {:==, value}},
        condition_type: {:operator, operator},
        semantics: operator.semantics().(value)
      }
  end

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
        %Condition{condition: {key, _}, condition_type: {:operator, _}, semantics: function},
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

  @spec to_dynamic_query(Condition.t()) :: {:ok, term} | {:error, term()}
  def to_dynamic_query(%Condition{condition: condition, condition_type: :const}),
    do: {:ok, dynamic(^condition)}

  def to_dynamic_query(%Condition{condition: {key, _} = condition, condition_type: {:operator, operator}}) do
    case operator.dynamic_query(key) do
      nil ->
        {:error, {:condition_unconvertible, condition}}

      query ->
        {:ok, query}
    end
  end

  def to_dynamic_query(%Condition{condition_type: other}),
    do: {:error, {:condition_unconvertible, other}}
end
