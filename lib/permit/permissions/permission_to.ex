defmodule Permit.Permissions.PermissionTo do
  @moduledoc false

  @doc ~S"""
  Private - mixed in by `Permit.Permissions`. Defines `permission_to/4`, `permission_to/5` functions in permission definition modules to def.
  """
  def mixin(condition_parser, condition_types_module \\ Permit.Types.ConditionTypes) do
    quote do
      @doc ~s"""
      Grants the permission to perform a named action on a certain resource under specific conditions.

      ## Example

          use Permit.Ecto.Permissions, actions_module: Permit.Phoenix.Actions

          def can(%{role: :user, id: user_id} = _user) do
            permit()
            |> permission_to(Article, author_id: user_id)
          end
      """
      @spec permission_to(
              Permit.Types.permissions(),
              Permit.Types.action_group(),
              Permit.Types.object_or_resource_module(),
              unquote(condition_types_module).condition_or_conditions()
            ) :: Permit.Types.permissions()
      def permission_to(permissions, action_group, resource, conditions) do
        Permit.Permissions.add_permission(
          permissions,
          action_group,
          resource,
          [],
          conditions,
          unquote(condition_parser)
        )
      end

      @doc ~s"""
      Grants the permission to perform a named action on a certain resource under specific conditions.

      ## Example

          use Permit.Ecto.Permissions, actions_module: Permit.Phoenix.Actions

          def can(%{role: :user} = _user) do
            permit()
            |> permission_to(:read, Article, [user, article], user.id: article.author_id)
          end
      """
      @spec permission_to(
              Permit.Types.permissions(),
              Permit.Types.action_group(),
              Permit.Types.object_or_resource_module(),
              list(),
              [unquote(condition_types_module).condition_or_conditions()]
            ) :: Permit.Types.permissions_code()
      defmacro permission_to(permissions, action_group, resource, bindings, conditions) do
        condition_parser = unquote(condition_parser)

        {escaped_bindings, escaped_conditions} =
          Permit.Permissions.escape_bindings_and_conditions(bindings, conditions)

        quote do
          Permit.Permissions.add_permission(
            unquote(permissions),
            unquote(action_group),
            unquote(resource),
            unquote(escaped_bindings),
            unquote(escaped_conditions),
            unquote(condition_parser)
          )
        end
      end
    end
  end
end
