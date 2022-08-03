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

  @spec to_dynamic_query(ConditionClauses.t()) :: {:ok, Ecto.Query.t()} | {:error, keyword()}
  def to_dynamic_query(%ConditionClauses{conditions: []}),
    do: {:ok, dynamic(false)}

  def to_dynamic_query(%ConditionClauses{conditions: conditions}) do
    conditions
    |> Enum.map(&Condition.to_dynamic_query/1)
    |> Enum.reduce({:ok, dynamic(true)}, fn
      {:ok, condition_query}, {:ok, acc} ->
        {:ok, dynamic(^acc and ^condition_query)}

      {:ok, _}, {:error, errors} ->
        {:error, errors}

      {:error, error}, {:error, errors} ->
        {:error, [error | errors]}

      {:error, error}, {:ok, _} ->
        {:error, [error]}
    end)
  end
end
