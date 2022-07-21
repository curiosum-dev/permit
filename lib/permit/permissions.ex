defmodule Permit.Permissions do
  @moduledoc """

  """

  defstruct conditions_by_action_resource: %{}

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.DNF
  alias Permit.Permissions.ConditionClauses

  @type conditions_by_action_and_resource :: %{
          {Types.controller_action(), Types.resource_module()} => DNF.t()
        }
  @type t :: %Permissions{conditions_by_action_resource: conditions_by_action_and_resource()}

  @spec new() :: Permissions.t()
  def new, do: %Permissions{}

  @spec new(conditions_by_action_and_resource()) :: Permissions.t()
  defp new(rca), do: %Permissions{conditions_by_action_resource: rca}

  @spec add(Permissions.t(), Types.controller_action(), Types.resource_module(), [any()]) ::
          Permissions.t()
  def add(permissions, action, resource, conditions) do
    permissions.conditions_by_action_resource
    |> Map.update({action, resource}, DNF.add_clauses(DNF.new(), conditions), fn
      nil -> DNF.add_clauses(DNF.new(), conditions)
      dnf -> DNF.add_clauses(dnf, conditions)
    end)
    |> new()
  end

  @spec clauses_list_for_action(Permissions.t(), Types.controller_action(), Types.resource()) ::
          ConditionClauses.t()
  def clauses_list_for_action(permissions, action, resource) do
    resource_module = resource_module_from_resource(resource)

    permissions.conditions_by_action_resource
    |> Map.get({action, resource_module})
    |> DNF.to_list()
  end

  @spec resource_module_from_resource(Types.resource()) :: Types.resource_module()
  defp resource_module_from_resource(resource) when is_atom(resource),
    do: resource

  defp resource_module_from_resource(resource) when is_struct(resource),
    do: resource.__struct__
end
