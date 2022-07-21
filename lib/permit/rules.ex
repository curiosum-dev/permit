defmodule Permit.Rules do
  @moduledoc """
  Provides functions used for defining the application's permission set.
  """
  @spec grant(any) :: Permit.t()
  def grant(role), do: %Permit{role: role}

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

  defp put_action(authorization, action, resource, condition)
    when not is_list(condition) do
      authorization
      |> put_action(action, resource, [condition])
  end

  defp put_action(authorization, action, resource, conditions) do
    authorization
    |> Permit.add_permission(action, resource, conditions)
  end
end
