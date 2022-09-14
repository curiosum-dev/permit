defmodule Permit.Permissions.Condition do
  @moduledoc """
     Condition
  """
  @enforce_keys [:condition, :condition_type]
  defstruct [:condition, :condition_type, :semantics, :explicit_query]

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.Condition.Operators
  require Permit.Permissions.Condition.Operators
  import Ecto.Query

  @type condition_type :: :const | :function_1 | :function_2 | {:operator, module()}
  @type t :: %Condition{
          condition: Types.condition(),
          condition_type: condition_type(),
          semantics: (any() -> boolean()),
          explicit_query: nil | Ecto.Query.t()
        }

  @eq_operators Operators.eq_operators()
  @eq Operators.eq()
  @operators Operators.all()

  @spec new(Types.condition()) :: Condition.t()
  def new({semantics_fun, query_fun})
    when is_function(semantics_fun, 1) and is_function(query_fun, 1) or
         is_function(semantics_fun, 2) and is_function(query_fun, 2) do
      semantics_fun
      |> new()
      |> put_query_function(query_fun)
    end

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

  @spec to_dynamic_query(Condition.t(), Types.resource(), Types.subject()) :: {:ok, Ecto.Query.DynamicExpr.t()} | {:error, term()}
  def to_dynamic_query(%Condition{condition: condition, condition_type: :const}, _subject, _resource),
    do: {:ok, dynamic(^condition)}

  def to_dynamic_query(%Condition{
        condition: {key, {_op, val, ops}} = condition,
        condition_type: {:operator, operator}
      }, _subject, _resource) do
    case operator.dynamic_query(key, ops) do
      nil ->
        {:error, {:condition_unconvertible, %{condition: condition, type: {:operator, operator}}}}

      query ->
        {:ok, query.(val)}
    end
  end


  def to_dynamic_query(%Condition{condition_type: other, condition: function, explicit_query: nil}, _, _) when is_function(function),
    do: {:error, {:condition_unconvertible, %{condition: function, type: other}}}

  def to_dynamic_query(%Condition{condition_type: :function_1, explicit_query: query_fn}, _subject, resource) when is_function(query_fn, 1),
    do: query_fn.(resource)

  def to_dynamic_query(%Condition{condition_type: :function_2, explicit_query: query_fn}, subject, resource) when is_function(query_fn, 2),
    do: query_fn.(subject, resource)

  defp put_query_function(%Condition{} = condition, query_fun) do
    %Condition{condition | explicit_query: query_fun}
  end
end
