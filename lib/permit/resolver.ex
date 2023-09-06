defmodule Permit.Resolver do
  @moduledoc """
  Basic implementation of `Permit.ResolverBase` behaviour. Resolves and checks authorization of records or lists of records based on provided loader functions and parameters.

  For a resolver implementation using Ecto for fetching resources, see `Permit.Ecto.Resolver` from the `permit_ecto` library.

  This module is to be considered a private API of the authorization framework.
  It should not be directly used by application code, but rather by wrappers
  providing integration with e.g. Plug or LiveView.
  """
  alias Permit.Types

  use Permit.ResolverBase

  @impl Permit.ResolverBase
  def resolve(
        subject,
        authorization_module,
        resource_module,
        action,
        %{loader: _, params: _} = meta,
        :one
      ) do
    with {_, true} <-
           {:pre_auth, authorized?(subject, authorization_module, resource_module, action)},
         resource when not is_nil(resource) <-
           fetch_resource(
             authorization_module,
             resource_module,
             action,
             subject,
             meta,
             :one
           ),
         {_, true} <- {:auth, authorized?(subject, authorization_module, resource, action)} do
      {:authorized, resource}
    else
      {:pre_auth, false} ->
        :unauthorized

      nil ->
        :not_found

      {:auth, false} ->
        :unauthorized
    end
  end

  @impl Permit.ResolverBase
  def resolve(
        subject,
        authorization_module,
        resource_module,
        action,
        %{loader: _, params: _} = meta,
        :all
      ) do
    with {_, true} <-
           {:pre_auth, authorized?(subject, authorization_module, resource_module, action)},
         list <-
           fetch_resource(
             authorization_module,
             resource_module,
             action,
             subject,
             meta,
             :all
           ),
         filtered_list <-
           Enum.filter(list, &authorized?(subject, authorization_module, &1, action)) do
      {:authorized, filtered_list}
    else
      {:pre_auth, false} ->
        :unauthorized
    end
  end

  @spec fetch_resource(
          module(),
          Types.resource_module(),
          Types.action_group(),
          Types.subject(),
          map(),
          :all | :one
        ) :: [struct()] | struct() | nil
  defp fetch_resource(
         _authorization_module,
         resource_module,
         action,
         subject,
         %{loader: loader, params: params},
         :all
       ) do
    case loader.(%{
           action: action,
           resource_module: resource_module,
           subject: subject,
           params: params
         }) do
      list when is_list(list) -> list
      nil -> []
      other_item -> [other_item]
    end
  end

  defp fetch_resource(
         _authorization_module,
         resource_module,
         action,
         subject,
         %{loader: loader, params: params},
         :one
       ) do
    case loader.(%{
           action: action,
           resource_module: resource_module,
           subject: subject,
           params: params
         }) do
      [record | _] -> record
      [] -> nil
      record -> record
    end
  end
end
