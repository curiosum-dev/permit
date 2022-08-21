defmodule Permit.Resolver do
  @moduledoc """
  This module is to be considered a private API of the authorization framework.
  It should not be directly used by application code, but rather by wrappers
  providing integration with e.g. Plug or LiveView.
  """
  alias Permit.Types
  require Permit

  @spec authorized_without_preloading?(
          Types.subject(),
          module(),
          Types.resource_module(),
          Types.controller_action()
        ) :: boolean()
  def authorized_without_preloading?(
        subject,
        authorization_module,
        resource_module,
        live_or_controller_action
      )
      when not is_nil(subject) do
    check(
      authorization_module,
      live_or_controller_action,
      resource_module,
      subject
    )
  end

  @spec authorize_with_preloading!(
          Types.subject(),
          module(),
          Types.resource_module(),
          Types.controller_action(),
          map(),
          function()
        ) :: {:authorized, Ecto.Schema.t()} | :unauthorized
  def authorize_with_preloading!(
        subject,
        authorization_module,
        resource_module,
        action,
        params,
        loader_fn
      )
      when not is_nil(subject) do
    with true <-
           authorized_without_preloading?(subject, authorization_module, resource_module, action),
         record when not is_nil(record) <-
           fetch_resource(authorization_module.repo, loader_fn, resource_module, params),
         true <-
           check(authorization_module, action, record, subject) do
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
          Types.controller_action(),
          Types.resource_module() | Types.resource(),
          Permit.HasRole.t()
        ) :: boolean()
  defp check(authorization_module, action, resource_or_module, subject) do
    authorization_module.actions_module.map(action)
    |> Enum.all?(fn action ->
      authorization_module.can(subject)
      |> Permit.verify_record(resource_or_module, action)
    end)
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
