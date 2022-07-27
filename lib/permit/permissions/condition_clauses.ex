defmodule Permit.Permissions.ConditionClauses do
  @moduledoc """
    Conjunction of conditions
  """

  defstruct conditions: []

  alias __MODULE__
  alias Permit.Types
  @type t :: %ConditionClauses{conditions: [Types.condition()]}

  @spec new([Types.condition()]) :: ConditionClauses.t()
  def new(conditions),
    do: %ConditionClauses{conditions: conditions}

  # Empty condition set means that an authorization subject is not authorized
  # to interact with a given record.
  @spec conditions_satisfied?(ConditionClauses.t(), Types.resource(), Types.subject()) :: boolean()
  def conditions_satisfied?(%ConditionClauses{conditions: []}, _record, _subject),
    do: false

  def conditions_satisfied?(%ConditionClauses{conditions: conditions}, record, subject)
      when is_struct(record) do
    conditions
    |> Enum.all?(& Condition.satisfied?(&1, record, subject))
  end
end
