defmodule Permit.Permissions do
  @moduledoc """

  """

  defstruct conditions_map: %{}

  alias __MODULE__
  alias Permit.Types
  alias Permit.Permissions.Condition
  alias Permit.Permissions.DisjunctiveNormalForm, as: DNF
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

  @spec add(Permissions.t(), Types.action_group(), Types.resource_module(), [Condition.t()]) ::
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

  @spec construct_query(
          Permissions.t(),
          Types.action_group(),
          Types.resource(),
          Types.subject(),
          module(),
          (Types.resource() -> Ecto.Query.t())
        ) ::
          {:ok, Ecto.Query.t()} | {:error, [term()]}
  def construct_query(permissions, action, resource, subject, actions_module, prefilter \\ & &1) do
    with {:ok, filter} <- transitive_query(permissions, actions_module, action, resource, subject) do
      resource
      |> resource_module_from_resource()
      |> prefilter.()
      |> where(^filter)
      |> then(&{:ok, &1})
    end
  end

  defp transitive_query(permissions, actions_module, action, resource, subject) do
    res_module = resource_module_from_resource(resource)

    functions = [
      condition: &conditions_defined_for?(permissions, &1, res_module),
      value:
        &(permissions.conditions_map
          |> Map.get({&1, res_module})
          |> DNF.to_dynamic_query(subject, resource)),
      empty: &throw({:undefined_condition, {&1, res_module}}),
      join: fn l -> Enum.reduce(l, &join_queries/2) end
    ]

    try do
      Actions.traverse_actions!(
        actions_module,
        action,
        functions
      )
    catch
      {:undefined_condition, _} = error ->
        {:error, error}
    end
  end

  @spec conditions_defined_for?(Permissions.t(), Types.controller_action(), Types.resource()) ::
          boolean()
  def conditions_defined_for?(permissions, action, resource) do
    permissions.conditions_map[{action, resource}]
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

  defp join_queries({:ok, query1}, {:ok, query2}),
    do: {:ok, query1 and query2}

  defp join_queries({:error, errors}, {:ok, _}),
    do: {:error, errors}

  defp join_queries({:ok, _}, {:error, errors}),
    do: {:error, errors}

  defp join_queries({:error, err1}, {:error, err2}),
    do: {:error, err1 ++ err2}
end
