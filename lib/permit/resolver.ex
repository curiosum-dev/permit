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
  def authorized_without_preloading?(subject, authorization_module, resource_module, action)
      when not is_nil(subject) do
    check(action, authorization_module, resource_module, subject)
  end

  @spec authorize_with_preloading!(
          Types.subject(),
          module(),
          Types.resource_module(),
          Types.controller_action(),
          function()
        ) :: {:authorized, [struct()]} | :unauthorized
  def authorize_with_preloading!(
        subject,
        authorization_module,
        resource_module,
        action,
        loader_fn
      )
      when not is_nil(subject) do
    with true <-
           check(action, authorization_module, resource_module, subject),
         records <-
           fetch_resource(authorization_module, resource_module, action, subject, loader_fn) do
      {:authorized, records}
    else
      _ -> :unauthorized
    end
  end

  @spec fetch_resource(
          module(),
          Types.resource_module(),
          Types.controller_action(),
          Permit.HasRole.t(),
          function()
        ) :: [struct()]
  defp fetch_resource(authorization_module, resource_module, action, subject, loader_fn) do
    subject
    |> authorization_module.accessible_by!(action, resource_module, loader_fn)
    |> IO.inspect(label: "#{__MODULE__} accesible")
    |> authorization_module.repo.all()
    |> IO.inspect(label: "#{__MODULE__} repo all")
  end

  @spec check(
          Types.controller_action(),
          module(),
          Types.resource_module() | Types.resource(),
          Permit.HasRole.t()
        ) :: boolean()
  defp check(action, authorization_module, resource_or_module, subject) do
    auth = authorization_module.can(subject)
    actions_module = authorization_module.actions_module()

    {:ok, permitted?} =
      Permit.Actions.traverse_actions(
        actions_module,
        action,
        &Permit.verify_record(auth, resource_or_module, &1)
      )

    permitted?
  end
end
