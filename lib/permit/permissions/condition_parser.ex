defmodule Permit.Permissions.ConditionParser do
  @moduledoc false
  alias Permit.Operators
  alias Permit.Permissions.ParsedCondition

  require Permit.Operators

  @eq_operators Operators.eq_operators()
  @operators_with_options Operators.with_options()
  @eq Operators.eq()
  @operators Operators.all()

  @behaviour Permit.Permissions.ConditionParserBase

  @impl true
  def build(condition, opts \\ [bindings: []])

  def build({key, {:not, nil}}, ops)
      when is_atom(key),
      do: build({key, nil}, [{:not, true} | ops])

  def build({key, nil}, ops)
      when is_atom(key) do
    not? = Keyword.get(ops, :not, false)

    %ParsedCondition{
      condition: {key, const_fn2(nil)},
      condition_type: {:operator, Operators.IsNil},
      semantics: Operators.IsNil.semantics({}, not: not?),
      not: not?
    }
  end

  def build({key, {{:not, operator}, nil}}, ops)
      when is_atom(key),
      do: build({key, {operator, nil}}, [{:not, true} | ops])

  def build({key, {operator, nil}}, ops)
      when operator in @eq_operators and is_atom(key),
      do: build({key, nil}, ops)

  def build(
        {key, {{:not, operator}, value}},
        ops
      )
      when is_atom(key) and not is_nil(value),
      do: build({key, {operator, value}}, [{:not, true} | ops])

  def build({key, {:not, value}}, ops)
      when is_atom(key) and not is_nil(value),
      do: build({key, {@eq, value}}, [{:not, true} | ops])

  def build({key, {{:not, operator_with_ops}, value, operators_opts}}, ops)
      when is_atom(key) and
             not is_nil(value),
      do: build({key, {operator_with_ops, value}}, [{:not, true} | operators_opts ++ ops])

  def build({key, {operator_with_ops, value, operators_opts}}, ops)
      when operator_with_ops in @operators_with_options and
             is_atom(key) and
             not is_nil(value),
      do: build({key, {operator_with_ops, value}}, operators_opts ++ ops)

  def build({key, {operator, value} = _condition}, ops)
      when operator in @operators and is_atom(key) and not is_nil(value) do
    case Operators.get(operator) do
      {:ok, module} ->
        val_fn = binding_fn(value, Keyword.get(ops, :bindings))

        condition_type = if Keyword.keyword?(value), do: :association, else: :operator

        %ParsedCondition{
          condition: {key, val_fn},
          condition_type: {condition_type, module},
          semantics: module.semantics(val_fn, ops),
          not: Keyword.get(ops, :not, false)
        }

      :error ->
        raise "Unsupported operator #{inspect(operator)}"
    end
  end

  # only value with binding e.g `field: subject.foo`
  def build({key, {{:., _, _}, _, _} = value}, ops)
      when is_atom(key),
      do: build({key, {@eq, value}}, ops)

  def build({key, value}, ops)
      when is_atom(key) and
             not is_nil(value) and
             not is_tuple(value),
      do: build({key, {@eq, value}}, ops)

  def build(true, _ops),
    do: %ParsedCondition{
      condition: true,
      condition_type: :const
    }

  def build(false, _ops),
    do: %ParsedCondition{
      condition: false,
      condition_type: :const
    }

  def build(function, _ops) when is_function(function, 1),
    do: %ParsedCondition{
      condition: function,
      condition_type: :function_1
    }

  def build(function, _ops) when is_function(function, 2),
    do: %ParsedCondition{
      condition: function,
      condition_type: :function_2
    }

  defp const_fn2(val),
    do: fn _, _ -> val end

  defp binding_fn(val, []),
    do: const_fn2(val)

  defp binding_fn(val, [subject]),
    do: binding_fn(val, [subject, :_])

  defp binding_fn(val, [subject, object]) do
    val
    |> Macro.prewalk(&map_struct_selector_to_ast(&1, [subject, object]))
    |> make_function2_ast(subject, object)
    |> Code.eval_quoted()
    |> elem(0)
  end

  defp map_struct_selector_to_ast(
         {{:., _, [{param, _, _}, field]}, [{:no_parens, true} | _] = meta, []} = expr,
         selectors
       ) do
    if param in selectors do
      {{:., [], [make_var_ast(param), field]}, meta, []}
    else
      expr
    end
  end

  defp map_struct_selector_to_ast(expression, _selectors),
    do: expression

  defp make_var_ast(variable),
    do: {variable, [], Elixir}

  defp make_function2_ast(body, arg1, arg2) do
    {:fn, [],
     [
       {:->, [],
        [
          [make_var_ast(arg1), make_var_ast(arg2)],
          body
        ]}
     ]}
  end
end
