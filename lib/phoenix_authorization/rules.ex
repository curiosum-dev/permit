defmodule PhoenixAuthorization.Rules do
  @moduledoc """
  Provides functions used for defining the application's permission set.
  """
  @spec grant(any) :: PhoenixAuthorization.t()
  def grant(role), do: %PhoenixAuthorization{role: role}

  def read(authorization, resource, conditions \\ true),
    do: put_action(authorization, :read, resource, conditions)

  def create(authorization, resource, conditions \\ true),
    do: put_action(authorization, :create, resource, conditions)

  def update(authorization, resource, conditions \\ true),
    do: put_action(authorization, :update, resource, conditions)

  def delete(authorization, resource, conditions \\ true),
    do: put_action(authorization, :delete, resource, conditions)

  def all(authorization, resource, conditions \\ true) do
    authorization
    |> create(resource, conditions)
    |> read(resource, conditions)
    |> update(resource, conditions)
    |> delete(resource, conditions)
  end

  defp put_action(authorization, action, resource, condition) when is_function(condition) do
    put_action(authorization, action, resource, [condition])
  end

  defp put_action(authorization, action, resource, conditions) do
    updated_condition_lists = [
      {action, %{resource => conditions}} | authorization.condition_lists
    ]

    Map.put(authorization, :condition_lists, updated_condition_lists)
  end
end
