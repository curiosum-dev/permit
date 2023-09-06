defmodule Permit.Permissions.ParsedConditionList do
  @moduledoc """
  Encapsulates the list of conditions having been parsed by an implementation of
  `Permit.Permissions`.

  This list is to be treated as a **conjunction** of conditions. The logical model
  of Permit implies that these conjunctions are then linked in an `OR` manner
  to form a disjunctive normal form - see more in `Permit.Permissions.DisjunctiveNormalForm`.

  Part of the private API, subject to changes and not to be used on the
  application level.
  """

  defstruct conditions: []

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.ParsedCondition

  @type t :: %__MODULE__{conditions: [ParsedCondition.t()]}

  @doc false
  @spec new([ParsedCondition.t()]) :: ParsedConditionList.t()
  def new(conditions) do
    %ParsedConditionList{conditions: conditions}
  end

  # Empty condition set means that an authorization subject is not authorized
  # to interact with a given record.
  @doc false
  @spec conditions_satisfied?(
          ParsedConditionList.t(),
          Types.object_or_resource_module(),
          Types.subject()
        ) ::
          boolean()
  def conditions_satisfied?(%ParsedConditionList{conditions: []}, _record, _subject),
    do: false

  @doc false
  def conditions_satisfied?(
        %ParsedConditionList{conditions: conditions},
        record,
        subject
      ) do
    conditions
    |> Enum.all?(&ParsedCondition.satisfied?(&1, record, subject))
  end
end
