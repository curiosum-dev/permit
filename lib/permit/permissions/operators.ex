defmodule Permit.Operators do
  @moduledoc """
  Represents the list of operators for usage in defining permission conditions, for example
  `Permit.Operators.Eq` defines the equality operator usable as `:==` or alternatively
  `:eq`, with given semantics.

  Part of the private API, subject to changes and not to be used on the application level.
  """

  alias Permit.Operators

  @operators [
    Operators.Eq,
    Operators.Gt,
    Operators.Ge,
    Operators.Lt,
    Operators.Le,
    Operators.Neq,
    Operators.Like,
    Operators.Ilike,
    Operators.Match,
    Operators.IsNil,
    Operators.In
  ]

  @operators_with_options [
    Operators.Like,
    Operators.Ilike
  ]

  @eq_operators [
    Operators.Eq,
    Operators.Neq
  ]

  @eq Operators.Eq

  @spec get(atom()) :: {:ok, module()} | :error
  def get(operator) do
    @operators
    |> Enum.reduce_while(nil, fn op, _ ->
      if operator in [op.symbol() | op.alternatives()] do
        {:halt, {:ok, op}}
      else
        {:cont, :error}
      end
    end)
  end

  defmacro eq_operators do
    @eq_operators
    |> Enum.reduce([], fn module, acc ->
      [module.symbol() | module.alternatives()] ++ acc
    end)
  end

  defmacro eq do
    @eq.symbol()
  end

  defmacro all do
    @operators
    |> Enum.reduce([], fn op, acc ->
      [op.symbol() | op.alternatives()] ++ acc
    end)
  end

  defmacro with_options do
    @operators_with_options
    |> Enum.reduce([], fn op, acc ->
      [op.symbol() | op.alternatives()] ++ acc
    end)
  end
end
