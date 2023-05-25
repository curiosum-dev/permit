defmodule Permit.Resolver do
  @moduledoc """
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
        %{loader_fn: _, params: _} = meta,
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
        %{loader_fn: _, params: _} = meta,
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
          Types.controller_action(),
          Permit.HasRole.t(),
          map(),
          :all | :one
        ) :: [struct()] | struct() | nil
  defp fetch_resource(
         _authorization_module,
         resource_module,
         action,
         subject,
         %{loader_fn: loader_fn, params: params},
         :all
       ) do
    case loader_fn.(action, resource_module, subject, params) do
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
         %{loader_fn: loader_fn, params: params},
         :one
       ) do
    case loader_fn.(action, resource_module, subject, params) do
      [record | _] -> record
      [] -> nil
      record -> record
    end
  end
end
