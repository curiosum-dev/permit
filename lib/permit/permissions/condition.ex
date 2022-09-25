defmodule Permit.Permissions.Condition do
  @moduledoc """
     Condition
  """
  @enforce_keys [:condition, :condition_type]
  defstruct [:condition, :condition_type, :semantics, :dynamic_query]

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.Condition.Operators
  require Permit.Permissions.Condition.Operators
  import Ecto.Query

  @type condition_type :: :const | :function_1 | :function_2 | {:operator, module()}
  @type t :: %Condition{
          condition: boolean()
            | {atom(), (struct(), struct() -> any())}
            | (struct(), struct() -> boolean())
            | (struct() -> boolean()),
          condition_type: condition_type(),
          semantics: (any(), struct(), struct() -> boolean()),
          dynamic_query: (struct(), struct() -> Ecto.Query.t())
        }

  @eq_operators Operators.eq_operators()
  @eq Operators.eq()
  @operators Operators.all()

  @spec new(Types.condition()) :: Condition.t()
  def new({key, condition}, [bindings: b]),
    do: new({key, Tuple.append(condition, [bindings: b])})

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
      condition: {key, const_fn2(nil)},
      condition_type: {:operator, Operators.IsNil},
      semantics: Operators.IsNil.semantics({}, not: true),
      dynamic_query: & {:ok, Operators.IsNil.dynamic_query(key, not: true).(&1)}
    }
  end

  def new({key, nil})
      when is_atom(key) do
    %Condition{
      condition: {key, const_fn2(nil)},
      condition_type: {:operator, Operators.IsNil},
      semantics: Operators.IsNil.semantics({}),
      dynamic_query:  & {:ok, Operators.IsNil.dynamic_query(key, []).(&1)}
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

  def new({key, {operator, value, ops} = condition})
      when is_atom(operator) and is_atom(key) and not is_nil(value) do
    case Operators.get(operator) do
      {:ok, module} ->
        val_fn = binding_fn(value, Keyword.get(ops, :bindings))
        query_fn =
          case module.dynamic_query(key, ops) do
           nil -> {:error, {:condition_unconvertible, %{condition: condition, type: {:operator, module}}}} |> const_fn1()
           query -> & {:ok, query.(&1)}
          end


        %Condition{
          condition: {key, val_fn},
          condition_type: {:operator, module},
          semantics: module.semantics(val_fn, ops),
          dynamic_query: query_fn
        }

      :error ->
        raise "Unsupported operator #{inspect(operator)}"
    end
  end

  def new({key, value})
      when is_atom(key) and not is_nil(value) do
    {:ok, operator} = Operators.get(@eq)

    %Condition{
      condition: {key, const_fn2(value)},
      condition_type: {:operator, operator},
      semantics: operator.semantics(const_fn2(value)),
      dynamic_query: & {:ok, operator.dynamic_query(key, []).(&1)}
    }
  end

  def new(true),
    do: %Condition{
      condition: true,
      condition_type: :const
    }

  def new(false),
    do: %Condition{
      condition: false,
      condition_type: :const
    }

  def new(function) when is_function(function, 1),
    do: %Condition{
      condition: function,
      condition_type: :function_1,
      dynamic_query: {:error, {:condition_unconvertible, %{condition: function, type: :function_1}}} |> const_fn1()
    }

  def new(function) when is_function(function, 2),
    do: %Condition{
      condition: function,
      condition_type: :function_2,
      dynamic_query: {:error, {:condition_unconvertible, %{condition: function, type: :function_2}}} |> const_fn2()
    }

  @spec satisfied?(Condition.t(), Types.resource(), Types.subject()) :: boolean()
  def satisfied?(%Condition{condition: condition, condition_type: :const}, _record, _subject),
    do: condition

  def satisfied?(
        %Condition{condition: {key, _}, condition_type: {:operator, _}, semantics: semantics},
        record,
        subject
      )
      when is_struct(record) do
    record
    |> Map.get(key)
    |> semantics.(subject, record)
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
  def to_dynamic_query(%Condition{condition: {_key, val_fn}, dynamic_query: query_fn}, subject, resource),
    do: val_fn.(subject, resource) |> query_fn.()

  def to_dynamic_query(%Condition{condition: condition, condition_type: :const}, _, _),
    do: {:ok, dynamic(^condition)}

  def to_dynamic_query(%Condition{condition_type: :function_2, dynamic_query: query_fn}, subject, resource),
    do: query_fn.(subject, resource)

  def to_dynamic_query(%Condition{condition_type: :function_1, dynamic_query: query_fn}, _subject, resource),
    do: query_fn.(resource)

  defp put_query_function(%Condition{} = condition, query_fun) do
    %Condition{condition | dynamic_query: query_fun}
  end

  defp const_fn1(val),
    do: fn _ -> val end

  defp const_fn2(val),
    do: fn _, _ -> val end

  defp binding_fn(val, nil),
    do: const_fn2(val)

  defp binding_fn(val, [subject]),
    do: binding_fn(val, [subject, :_])

  defp binding_fn(val, [subject, object]) do
    IO.inspect(val, label: :val)
    {:fn, [],
      [
        {:->, [],
          [
            [
              {subject, [if_undefined: :apply], Elixir},
              {object, [if_undefined: :apply], Elixir}
            ],
            val
          ]}
      ]}
      |> Code.eval_quoted()
      |> elem(0)
  end
end
