defmodule Permit.Permissions.Condition do
  @moduledoc """
     Condition
  """
  @enforce_keys [:condition, :condition_type]
  defstruct [:condition, :condition_type, :semantics]

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.Condition.Operators
  require Permit.Permissions.Condition.Operators
  import Ecto.Query

  @type condition_type :: :const | :function_1 | :function_2 | {:operator, module()}
  @type t :: %Condition{
          condition: Types.condition(),
          condition_type: condition_type(),
          semantics: (any() -> boolean())
        }

  @eq_operators Operators.eq_operators()
  @eq Operators.eq()
  @operators Operators.all()

  @spec new(Types.condition()) :: Condition.t()
  def new({key, {:not, nil}})
      when is_atom(key) do
    %Condition{
      condition: {key, {@eq, nil, [not: true]}},
      condition_type: {:operator, Operators.IsNil},
      semantics: Operators.IsNil.semantics(not: true).(nil)
    }
  end

  def new({key, nil})
      when is_atom(key) do
    %Condition{
      condition: {key, {@eq, nil, []}},
      condition_type: {:operator, Operators.IsNil},
      semantics: Operators.IsNil.semantics().(nil)
    }
  end

  def new({key, {operator, value}})
      when operator in @operators and is_atom(key) and not is_nil(value),
      do: new({key, {operator, value, []}})

  def new({key, {{:not, operator}, value}})
      when operator in @operators and is_atom(key) and not is_nil(value),
      do: new({key, {operator, value, not: true}})

  def new({key, {{:not, operator}, value, ops}})
      when operator in @operators and is_atom(key) and not is_nil(value),
      do: new({key, {operator, value, [{:not, true}, ops]}})

  def new({key, {operator, nil, ops}})
      when operator in @eq_operators and is_atom(key) do
    if Keyword.get(ops, :not, false) do
      new({key, {:not, nil}})
    else
      new({key, nil})
    end
  end

  def new({key, {operator, value, ops}})
      when is_atom(operator) and is_atom(key) and not is_nil(value) do
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

  def new({key, value})
      when is_atom(key) and not is_nil(value) do
    {:ok, operator} = Operators.get(@eq)

    %Condition{
      condition: {key, {@eq, value, []}},
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

  def satisfied?(%Condition{condition: _fun, condition_type: :function_2}, _record, subject)
      when is_nil(subject),
      do:
        raise(
          "Unable to use function/2 condition feature without subject. First argument of this function is nonexisting subject"
        )

  def satisfied?(%Condition{condition: function, condition_type: :function_2}, record, subject),
    do: !!function.(subject, record)

  @spec to_dynamic_query(Condition.t()) :: {:ok, Ecto.Query.DynamicExpr.t()} | {:error, term()}
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
