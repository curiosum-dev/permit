defmodule Permit.Permissions.DNF do
  @moduledoc """
    Conditions written as logical formula in disjunctive normal form
    Disjunction of dual clauses
  """

  defstruct disjunctions: []

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.ConditionClauses
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
end
