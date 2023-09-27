defmodule Permit.Permissions.DisjunctiveNormalForm do
  @moduledoc """
  Describes conditions written as logical formula in disjunctive normal form.

  Example of a compound condition in DNF is:
  ```
  (condition 1 AND condition 2)
  OR (condition 3)
  OR (condition 4 AND condition 5 AND condition 6)
  ```

  Part of the private API, subject to changes and not to be used on the
  application level.
  """
  defstruct disjunctions: []

  alias __MODULE__, as: DNF
  alias Permit.Permissions.ParsedCondition
  alias Permit.Permissions.ParsedConditionList
  alias Permit.Types
  @type t :: %DNF{disjunctions: [ParsedConditionList.t()]}

  @spec new([ParsedConditionList.t()]) :: DNF.t()
  def new(disjunctions \\ []) do
    %DNF{disjunctions: disjunctions}
  end

  @spec add_clauses(DNF.t(), [ParsedCondition.t()]) :: DNF.t()
  def add_clauses(nil, clauses) do
    %DNF{disjunctions: [ParsedConditionList.new(clauses)]}
  end

  def add_clauses(dnf, clauses) do
    new_disjunctions = [ParsedConditionList.new(clauses) | dnf.disjunctions]

    %DNF{dnf | disjunctions: new_disjunctions}
  end

  @spec any_satisfied?(DNF.t(), Types.object_or_resource_module(), Types.subject()) :: boolean()
  def any_satisfied?(%DNF{disjunctions: disjunctions}, record, subject) do
    disjunctions
    |> Enum.any?(&ParsedConditionList.conditions_satisfied?(&1, record, subject))
  end

  @spec concatenate(DNF.t(), DNF.t()) :: DNF.t()
  def concatenate(%DNF{disjunctions: d1}, %DNF{disjunctions: d2}) do
    %DNF{disjunctions: d1 ++ d2}
  end
end
