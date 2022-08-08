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

  @spec new(Types.condition()) :: Condition.t()
  def new({key, {operator, value}})
      when is_atom(operator) and is_atom(key),
      do: new({key, {operator, value, []}})

    def new({key, {{:not, operator}, value}})
      when is_atom(operator) and is_atom(key),
      do: new({key, {operator, value, not: true}})

  def new({key, {{:not, operator}, value, ops}})
      when is_atom(operator) and is_atom(key),
        do: new({key, {operator, value, [{:not, true}, ops]}})

  def new({key, {operator, value, ops}})
      when is_atom(operator) and is_atom(key) do
    case Operators.get(operator) do
      {:ok, module} ->
        %Condition{
          condition: {key, {operator, value, ops}},
          condition_type: {:operator, module},
          semantics: module.semantics(ops).(value)
        }

      :error ->
        raise "Unsupported operator #{inspect(operator)}"
    end
  end

  def new({key, nil})
      when is_atom(key) do
    {:ok, operator} = Operators.get(:is_nil)

    %Condition{
      condition: {key, nil},
      condition_type: {:operator, operator},
      semantics: operator.semantics().(nil)
    }
  end

  def new({key, value})
      when is_atom(key) do
    {:ok, operator} = Operators.get(:==)

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

  def to_dynamic_query(%Condition{
        condition: {key, {_op, val, ops}} = condition,
        condition_type: {:operator, operator}
      }) do
    case operator.dynamic_query(key, ops) do
      nil ->
        {:error, {:condition_unconvertible, condition}}

      query ->
        {:ok, query.(val)}
    end
  end

  def to_dynamic_query(%Condition{condition_type: other}),
    do: {:error, {:condition_unconvertible, other}}
end
