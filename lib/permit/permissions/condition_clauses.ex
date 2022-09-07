defmodule Permit.Permissions.ConditionClauses do
  @moduledoc """
    Conjunction of conditions
  """

  defstruct conditions: []

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.Condition
  import Ecto.Query
  @type t :: %ConditionClauses{conditions: [Condition.t()]}

  @spec new([Types.condition()]) :: ConditionClauses.t()
  def new(conditions) do
    conditions
    |> Enum.map(&Condition.new/1)
    |> then(&%ConditionClauses{conditions: &1})
  end

  # Empty condition set means that an authorization subject is not authorized
  # to interact with a given record.
  @spec conditions_satisfied?(ConditionClauses.t(), Types.resource(), Types.subject()) ::
          boolean()
  def conditions_satisfied?(%ConditionClauses{conditions: []}, _record, _subject),
    do: false

  def conditions_satisfied?(%ConditionClauses{conditions: conditions}, record, subject) do
    conditions
    |> Enum.all?(&Condition.satisfied?(&1, record, subject))
  end

  @spec to_dynamic_query(ConditionClauses.t()) ::
          {:ok, Ecto.Query.DynamicExpr.t()} | {:error, keyword()}
  def to_dynamic_query(%ConditionClauses{conditions: []}),
    do: {:ok, dynamic(false)}

  def to_dynamic_query(%ConditionClauses{conditions: conditions}) do
    conditions
    |> Enum.map(&Condition.to_dynamic_query/1)
    |> case do
      [] ->
        {:ok, dynamic(true)}

      [{:error, error}] when not is_list(error) ->
        {:error, [error]}

      list ->
        Enum.reduce(list, & join_queries/2)
    end
  end

  defp join_queries({:ok, condition_query}, {:ok, acc}),
    do: {:ok, dynamic(^acc and ^condition_query)}

  defp join_queries({:ok, _}, {:error, errors}),
    do: {:error, errors}

  defp join_queries({:error, err1}, {:error, err2}) when is_tuple(err2),
    do: {:error, [err1, err2]}

  defp join_queries({:error, error}, {:error, errors}) when is_list(errors),
    do: {:error, [error | errors]}

  defp join_queries({:error, error}, {:ok, _}),
    do: {:error, [error]}
end
