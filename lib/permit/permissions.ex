defmodule Permit.Permissions do
  @moduledoc """

  """

  defstruct conditions_map: %{}

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.DisjunctiveNormalForm, as: DNF
  alias Permit.Permissions.UndefinedConditionError
  alias Permit.Actions
  import Ecto.Query

  @type conditions_by_action_and_resource :: %{
          {Types.action_group(), Types.resource_module()} => DNF.t()
        }
  @type t :: %Permissions{conditions_map: conditions_by_action_and_resource()}

  @spec new() :: Permissions.t()
  def new, do: %Permissions{}

  @spec new(conditions_by_action_and_resource()) :: Permissions.t()
  defp new(rca), do: %Permissions{conditions_map: rca}

  @spec add(Permissions.t(), Types.action_group(), Types.resource_module(), [
          Types.condition()
        ]) ::
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

  @spec construct_query(Permissions.t(), Types.action_group(), Types.resource(), module(), (Types.resource() -> Ecto.Query.t())) ::
          {:ok, Ecto.Query.t()} | {:error, [term()]}
  def construct_query(permissions, action, resource, actions_module, prefilter \\ & &1) do
    resource = resource_module_from_resource(resource)

    IO.inspect(actions_module, label: "module in #{__MODULE__}")

    with {:ok, {:ok, filter}} <- Actions.construct_query_transitively!(
      actions_module,
      {action, resource},
      & conditions_defied_for?(permissions, &1),
      fn key ->
        permissions.conditions_map
        |> Map.get(key)
        |> DNF.to_dynamic_query()
      end,
      & join_queries(&1)) do
    resource
    |> prefilter.()
    |> where(^filter)
    |> then(&{:ok, &1})
    end
  end



  defp join_queries(listof_maybe_queries) do
    listof_maybe_queries
    |> Enum.reduce(fn
        {:ok, query1}, {:ok, query2} -> {:ok, query1 and query2}
        {:error, errors}, {:ok, _} -> {:error, errors}
        {:ok, _}, {:error, errors} -> {:error, errors}
        {:error, err1}, {:error, err2} -> {:error, err1 ++ err2}
    end)
  end

  @spec conditions_defied_for?(Permissions.t(), {Types.controller_action(), Types.resource()}) :: boolean()
  def conditions_defied_for?(permissions, {_, _} = key) do
    permissions.conditions_map[key]
    |> case do
      nil -> false
      _ -> true
    end
  end

  @spec join(Permissions.t(), Permissions.t()) :: Permissions.t()
  def join(p1, p2) do
    Map.merge(p1, p2, fn _k, dnf1, dnf2 ->
      DNF.join(dnf1, dnf2)
    end)
  end

  @spec dnf_for_action_and_record(Permissions.t(), Types.action_group(), Types.resource()) ::
          DNF.t()
  defp dnf_for_action_and_record(permissions, action, resource) do
    resource_module = resource_module_from_resource(resource)

    permissions.conditions_map
    |> Map.get({action, resource_module}, DNF.new())
  end

  @spec resource_module_from_resource(Types.resource()) :: Types.resource_module()
  defp resource_module_from_resource(resource) when is_atom(resource),
    do: resource

  defp resource_module_from_resource(resource) when is_struct(resource),
    do: resource.__struct__
end
