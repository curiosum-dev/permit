defmodule Permit.Permissions.ConditionClauses do
  @moduledoc """
    Conjunction of conditions
  """

  defstruct conditions: []

  alias __MODULE__
  @type t :: %ConditionClauses{conditions: [any()]}

  def new(conditions) do
    %ConditionClauses{conditions: conditions}
  end

  # Empty condition set means that an authorization subject is not authorized
  # to interact with a given record.
  def conditions_satisfied?(%ConditionClauses{conditions: []}, _record, _ops), do: false

  def conditions_satisfied?(%ConditionClauses{conditions: [true]}, _record, _ops), do: true

  def conditions_satisfied?(%ConditionClauses{conditions: conditions}, module, _ops) when is_atom(module) do
    conditions
    |> Enum.all?(&(!!&1))
  end

  def conditions_satisfied?(%ConditionClauses{conditions: conditions}, record, subject) when is_struct(record) do
    conditions
    |> Enum.all?(fn
      {field, expected_value} ->
        actual = Map.get(record, field)
        expected_value == actual

      function when is_function(function, 1) ->
        !!function.(record)

      function when is_function(function, 2) ->
        !!function.(subject, record)
    end)
  end
end
