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

  def conditions_satisfied?(%ConditionClauses{conditions: [true]}, _record, _subject),
    do: true

  def conditions_satisfied?(%ConditionClauses{conditions: conditions}, module, _subject)
      when is_atom(module) do
    conditions
    |> Enum.all?(&(!!&1))
  end

  def conditions_satisfied?(%ConditionClauses{conditions: conditions}, record, subject)
      when is_struct(record) do
    conditions
    |> Enum.all?(& valid?(&1, record, subject))
  end

  @spec valid?(Types.condition(), Type.resource(), Type.subject()) :: boolean()
  defp valid?({field, expected_value}, record, _subject) do
    record
    |> Map.get(field)
    |> Kernel.==(expected_value)
  end

  defp valid?(function, record, _subject) when is_function(function, 1),
    do: !!function.(record)

  defp valid?(function, record, subject) when is_function(function, 2),
    do: !!function.(subject, record)
end
