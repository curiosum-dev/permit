defmodule Permit.Resolver do
  @moduledoc """
  This module is to be considered a private API of the authorization framework.
  It should not be directly used by application code, but rather by wrappers
  providing integration with e.g. Plug or LiveView.
  """
  alias Permit.Types
  require Permit
  import Permit.Helpers, only: [resource_module_from_resource: 1]

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

  @spec authorize_with_singular_preloading!(
          Types.subject(),
          module(),
          Types.resource_module(),
          Types.controller_action(),
          function(),
          function()
        ) :: {:authorized, [struct()]} | :unauthorized
  def authorize_with_singular_preloading!(
        subject,
        authorization_module,
        resource_module,
        action,
        prefilter,
        postfilter
      )
      when not is_nil(subject) do
    authorization_checker = fn ->
      check(action, authorization_module, resource_module, subject)
    end

    authorize_and_preload_logic(
      authorization_checker,
      resource_fetcher(authorization_module, resource_module, action, subject, prefilter, postfilter, :one),
      &is_nil/1,
      construct_existence_checker(authorization_module, resource_module, prefilter)
    )
  end

  @spec authorize_with_preloading!(
          Types.subject(),
          module(),
          Types.resource_module(),
          Types.controller_action(),
          function(),
          function()
        ) :: {:authorized, [struct()]} | :unauthorized | :not_found
  def authorize_with_preloading!(
        subject,
        authorization_module,
        resource_module,
        action,
        prefilter,
        postfilter
      )
      when not is_nil(subject) do
    authorization_checker = fn ->
      check(action, authorization_module, resource_module, subject)
    end

    authorize_and_preload_logic(
      authorization_checker,
      resource_fetcher(authorization_module, resource_module, action, subject, prefilter, postfilter, :all),
      &Enum.empty?/1,
      construct_existence_checker(authorization_module, resource_module, prefilter)
    )
  end

  defp authorize_and_preload_logic(
         authorization_checker,
         fetcher,
         empty?,
         existence_checker
       ) do
    with {_, true} <- {:auth, authorization_checker.()},
         resource <- fetcher.(),
         {_, false} <- {:empty, empty?.(resource)} do
      {:authorized, resource}
    else
      {:auth, false} -> :unauthorized
      {:empty, true} -> existence_checker.()
    end
  end

  defp check_existence(authorization_module, resource, prefilter) do
    resource
    |> resource_module_from_resource()
    |> prefilter.()
    |> authorization_module.repo.exists?()
  end

  @spec resource_fetcher(
          module(),
          Types.resource_module(),
          Types.controller_action(),
          Permit.HasRole.t(),
          function(),
          function(),
          :all | :one
        ) :: (() -> [struct()] | struct() | nil)
  defp resource_fetcher(
         authorization_module,
         resource_module,
         action,
         subject,
         prefilter,
         postfilter,
         fetching_method
       ) do
    fetching_method = &apply(authorization_module.repo, fetching_method, [&1])

    fn ->
      subject
      |> authorization_module.accessible_by!(action, resource_module, prefilter)
      |> postfilter.()
      |> fetching_method.()
    end
  end

  defp construct_existence_checker(authorization_module, resource_module, prefilter) do
    fn ->
      case check_existence(authorization_module, resource_module, prefilter) do
        true -> :unauthorized
        false -> :not_found
      end
    end
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
    verify_fn = &Permit.verify_record(auth, resource_or_module, &1)

    Permit.Actions.verify_transitively!(actions_module, action, verify_fn)
  end
end
