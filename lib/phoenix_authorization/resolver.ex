defmodule PhoenixAuthorization.Resolver do
  @moduledoc """
  This module is to be considered a private API of the authorization framework.
  It should not be directly used by application code, but rather by wrappers
  providing integration with e.g. Plug or LiveView.
  """
  alias PhoenixAuthorization.Types

  @spec authorized_without_preloading?(
          Types.subject(),
          module(),
          Types.resource_module(),
          Types.controller_action(),
          keyword(Types.crud())
        ) :: boolean()
  def authorized_without_preloading?(
        subject,
        authorization_module,
        resource_module,
        live_or_controller_action,
        action_crud_mapping
      )
      when not is_nil(subject) do
    Enum.any?(subject.__struct__.roles(subject), fn role_data ->
      check(
        authorization_module,
        crud_action(live_or_controller_action, action_crud_mapping),
        role_data,
        resource_module,
        subject
      )
    end)
  end

  @spec authorize_with_preloading!(
          Types.subject(),
          module(),
          Types.resource_module(),
          Types.controller_action(),
          keyword(Types.crud()),
          map(),
          function()
        ) :: {:authorized, Ecto.Schema.t()} | :unauthorized
  def authorize_with_preloading!(
        subject,
        authorization_module,
        resource_module,
        live_or_controller_action,
        action_crud_mapping,
        params,
        loader_fn
      )
      when not is_nil(subject) do
    with true <-
           authorized_without_preloading?(
             subject,
             authorization_module,
             resource_module,
             live_or_controller_action,
             action_crud_mapping
           ),
         record when not is_nil(record) <-
           fetch_resource(authorization_module.repo, loader_fn, resource_module, params),
         true <-
           Enum.any?(subject.__struct__.roles(subject), fn role_data ->
             check(
               authorization_module,
               crud_action(live_or_controller_action, action_crud_mapping),
               role_data,
               record,
               subject
             )
           end) do
      {:authorized, record}
    else
      _ -> :unauthorized
    end
  end

  @spec fetch_resource(
          Ecto.Repo.t(),
          function(),
          Types.resource_module(),
          map()
        ) :: struct() | nil
  defp fetch_resource(repo, loader_fn, resource_module, params) do
    id_param_name = "id"
    id_param_value = params[id_param_name]

    loader_fn = loader_fn || default_loader_fn(repo, resource_module, id_param_name)

    case loader_fn.(id_param_value) do
      nil ->
        raise Ecto.NoResultsError, queryable: resource_module

      record ->
        record
    end
  end

  @spec check(
          module(),
          Types.crud(),
          Types.role_record(),
          Types.resource_module() | Types.resource(),
          Types.subject()
        ) :: boolean()
  defp check(authorization_module, crud_action, role_data, resource_or_module, subject)

  defp check(authorization_module, :read, role_data, resource_or_module, subject) do
    authorization_module.can(role_data, subject) |> authorization_module.read?(resource_or_module)
  end

  defp check(authorization_module, :create, role_data, resource_or_module, subject) do
    authorization_module.can(role_data, subject)
    |> authorization_module.create?(resource_or_module)
  end

  defp check(authorization_module, :update, role_data, resource_or_module, subject) do
    authorization_module.can(role_data, subject)
    |> authorization_module.update?(resource_or_module)
  end

  defp check(authorization_module, :delete, role_data, resource_or_module, subject) do
    authorization_module.can(role_data, subject)
    |> authorization_module.delete?(resource_or_module)
  end

  @spec crud_action(atom(), keyword(Types.crud())) :: Types.crud()
  defp crud_action(:index, _opts), do: :read
  defp crud_action(:show, _opts), do: :read
  defp crud_action(:new, _opts), do: :create
  defp crud_action(:create, _opts), do: :create
  defp crud_action(:edit, _opts), do: :update
  defp crud_action(:update, _opts), do: :update
  defp crud_action(:delete, _opts), do: :delete

  defp crud_action(controller_action, action_crud_mapping) do
    action_crud_mapping[controller_action]
  end

  @spec default_loader_fn(Ecto.Repo.t(), Types.resource_module(), Types.id_param_name()) ::
          Types.loader()
  defp default_loader_fn(repo, resource_module, "id") do
    fn id ->
      repo.get(resource_module, id)
    end
  end

  defp default_loader_fn(repo, resource_module, id_param_name) do
    id_param_atom = String.to_existing_atom(id_param_name)

    fn id ->
      repo.get_by(resource_module, [{id_param_atom, id}])
    end
  end
end
