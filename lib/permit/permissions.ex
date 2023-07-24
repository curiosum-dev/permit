defmodule Permit.Permissions do
  @moduledoc """

  """

  defstruct conditions_map: %{}

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.ParsedCondition
  alias Permit.Permissions.DisjunctiveNormalForm, as: DNF

  @type conditions_by_action_and_resource :: %{
          {Types.action_group(), Types.resource_module()} => DNF.t()
        }
  @type t :: %Permissions{conditions_map: conditions_by_action_and_resource()}

  @spec new() :: Permissions.t()
  def new, do: %Permissions{}

  @spec new(conditions_by_action_and_resource()) :: Permissions.t()
  defp new(rca), do: %Permissions{conditions_map: rca}

  @spec add(Permissions.t(), Types.action_group(), Types.resource_module(), [ParsedCondition.t()]) ::
          Permissions.t()
  def add(permissions, action, resource, conditions) do
    permissions.conditions_map
    |> Map.update({action, resource}, DNF.add_clauses(DNF.new(), conditions), fn dnf ->
      DNF.add_clauses(dnf, conditions)
    end)
    |> new()
  end

  @spec granted?(Permissions.t(), Types.action_group(), Types.resource(), Types.subject()) ::
          boolean()
  def granted?(permissions, action, record, subject) do
    permissions
    |> dnf_for_action_and_record(action, record)
    |> DNF.any_satisfied?(record, subject)
  end

  @spec join(Permissions.t(), Permissions.t()) :: Permissions.t()
  def join(p1, p2) do
    Map.merge(p1.conditions_map, p2.conditions_map, fn
      _k, dnf1, dnf2 -> DNF.join(dnf1, dnf2)
    end)
    |> then(&%Permissions{conditions_map: &1})
  end

  @spec dnf_for_action_and_record(Permissions.t(), Types.action_group(), Types.resource()) ::
          DNF.t()
  defp dnf_for_action_and_record(permissions, action, resource) do
    resource_module = resource_module_from_resource(resource)

    permissions.conditions_map
    |> Map.get({action, resource_module}, DNF.new())
  end

  @spec resource_module_from_resource(Types.resource()) :: Types.resource_module()
  def resource_module_from_resource(resource) when is_atom(resource),
    do: resource

  def resource_module_from_resource(resource) when is_struct(resource),
    do: resource.__struct__
end
