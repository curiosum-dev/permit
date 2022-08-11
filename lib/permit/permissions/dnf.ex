defmodule Permit.Permissions.DNF do
  @moduledoc """
    Conditions written as logical formula in disjunctive normal form
    Disjunction of dual clauses
  """

  defstruct disjunctions: []

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.ConditionClauses
  import Ecto.Query
  @type t :: %DNF{disjunctions: [ConditionClauses.t()]}

  @spec new([ConditionClauses.t()]) :: DNF.t()
  def new(disjunctions \\ []) do
    %DNF{disjunctions: disjunctions}
  end

  @spec add_clauses(DNF.t(), [any()]) :: DNF.t()
  def add_clauses(nil, clauses) do
    %DNF{disjunctions: [ConditionClauses.new(clauses)]}
  end

  def add_clauses(dnf, clauses) do
    new_disjunctions = [ConditionClauses.new(clauses) | dnf.disjunctions]

    %DNF{dnf | disjunctions: new_disjunctions}
  end

  @spec any_satisfied?(DNF.t(), Types.resource(), Types.subject()) :: boolean()
  def any_satisfied?(%DNF{disjunctions: disjunctions}, record, subject) do
    disjunctions
    |> Enum.any?(&ConditionClauses.conditions_satisfied?(&1, record, subject))
  end

  @spec to_query(DNF.t(), Types.resource_module()) :: {:ok, Ecto.Query.t()} | {:error, term()}
  def to_query(%DNF{disjunctions: disjunctions}, record) do
    with {:ok, filter} <- maybe_convert(disjunctions) do
      record
      |> where(^filter)
      |> then(&{:ok, &1})
    end
  end

  defp maybe_convert(disjunctions) do
    disjunctions
    |> Enum.map(&ConditionClauses.to_dynamic_query/1)
    |> Enum.reduce({:ok, dynamic(false)}, fn
      {:ok, conditions_query}, {:ok, acc} ->
        {:ok, dynamic(^acc or ^conditions_query)}

      {:ok, _}, {:error, errors} ->
        {:error, errors}

      {:error, es}, {:error, errors} ->
        {:error, es ++ errors}

      {:error, errors}, {:ok, _} ->
        {:error, errors}
    end)
  end
end
