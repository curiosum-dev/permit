defmodule Permit.Permissions.ActionFunctions do
  @moduledoc false

  @doc ~S"""
  Private - mixed in by `Permit.Permissions`. Defines `read/4`, `read/3` etc. functions in permission definition modules, based on defined actions.
  """
  def named_actions_mixin(
        actions_module,
        caller,
        decorator,
        condition_types_module \\ Permit.Types.ConditionTypes
      ) do
    Macro.expand(actions_module, caller)
    |> Permit.Actions.list_groups()
    |> Enum.map(fn name ->
      quote do
        @doc ~s"""
        Grants the permission to perform the :#{unquote(name)} action on a certain resource under specific conditions.

        ## Example

            use Permit.Ecto.Permissions, actions_module: Permit.Phoenix.Actions

            def can(%{role: :user} = _user) do
              permit()
              |> #{unquote(name)}(Article, [user, article], user.id: article.author_id)
            end
        """
        @spec unquote(name)(
                Permit.Types.permissions(),
                Permit.Types.object_or_resource_module(),
                list(),
                unquote(condition_types_module).condition_or_conditions()
              ) :: Permit.Types.permissions_code()
        defmacro unquote(name)(authorization, resource, bindings, conditions) do
          action = unquote(name)

          decorator = unquote(decorator)

          {escaped_bindings, escaped_conditions} =
            Permit.Permissions.escape_bindings_and_conditions(bindings, conditions)

          quote do
            Permit.Permissions.add_permission(
              unquote(authorization),
              unquote(action),
              unquote(resource),
              unquote(escaped_bindings),
              unquote(escaped_conditions),
              unquote(decorator)
            )
          end
        end

        @doc ~s"""
        Grants the permission to perform the :#{unquote(name)} action on a certain resource under specific conditions.

        ## Example

            use Permit.Ecto.Permissions, actions_module: Permit.Phoenix.Actions

            def can(%{role: :user, id: user_id} = _user) do
              permit()
              |> #{unquote(name)}(Article, author_id: user_id)
            end
        """
        @spec unquote(name)(
                Permit.Types.permissions(),
                Permit.Types.object_or_resource_module(),
                unquote(condition_types_module).condition_or_conditions
              ) :: Permit.Types.permissions()
        def unquote(name)(permissions, resource, conditions) do
          permissions
          |> __MODULE__.permission_to(unquote(name), resource, conditions)
        end

        @doc ~s"""
        Grants the permission to perform the :#{unquote(name)} action on a certain resource regardless of any conditions.

        ## Example

            use Permit.Ecto.Permissions, actions_module: Permit.Phoenix.Actions

            def can(%{role: :admin} = _user) do
              permit()
              |> #{unquote(name)}(Article)
            end
        """
        @spec unquote(name)(
                Permit.Types.permissions(),
                Permit.Types.object_or_resource_module()
              ) :: Permit.Types.permissions()
        def unquote(name)(permissions, resource) do
          permissions
          |> __MODULE__.permission_to(unquote(name), resource, true)
        end
      end
    end)
  end

  @doc ~S"""
  Private - mixed in by `Permit.Permissions`. Defines `all/4`, `all/3` in permission definition modules.
  """
  def all_actions_mixin(actions_module, decorator, condition_types_module \\ Permit.Types) do
    quote do
      @doc ~s"""
      Grants the permission to perform all defined actions on a certain resource under specific conditions.

      ## Example

          use Permit.Ecto.Permissions, actions_module: Permit.Phoenix.Actions

          def can(%{role: :user} = _user) do
            permit()
            |> all(Article, [user, article], user.id: article.author_id)
          end
      """
      @spec all(
              Permit.Types.permissions(),
              Permit.Types.object_or_resource_module(),
              list(),
              unquote(condition_types_module).condition_or_conditions
            ) :: Permit.Types.permissions_code()
      defmacro all(authorization, resource, bindings, conditions) do
        actions_module = unquote(actions_module)
        decorator = unquote(decorator)

        {escaped_bindings, escaped_conditions} =
          Permit.Permissions.escape_bindings_and_conditions(bindings, conditions)

        quote do
          actions_module()
          |> Permit.Actions.list_groups()
          |> Enum.reduce(unquote(authorization), fn group, auth ->
            Permit.Permissions.add_permission(
              auth,
              group,
              unquote(resource),
              unquote(escaped_bindings),
              unquote(escaped_conditions),
              unquote(decorator)
            )
          end)
        end
      end

      @doc ~s"""
      Grants the permission to perform all defined actions on a certain resource under specific conditions.

      ## Example

          use Permit.Ecto.Permissions, actions_module: Permit.Phoenix.Actions

          def can(%{role: :user, id: user_id} = _user) do
            permit()
            |> all(Article, author_id: user_id)
          end
      """
      @spec all(
              Permit.Types.permissions(),
              Permit.Types.object_or_resource_module(),
              unquote(condition_types_module).condition_or_conditions
            ) :: Permit.Types.permissions()
      def all(authorization, resource, conditions) do
        unquote(actions_module)
        |> Permit.Actions.list_groups()
        |> Enum.reduce(authorization, fn group, auth ->
          __MODULE__.permission_to(auth, group, resource, conditions)
        end)
      end

      @doc ~s"""
      Grants the permission to perform all defined actions on a certain resource regardless of any conditions.

      def can(%{role: :admin} = _user) do
        permit()
        |> all(Article)
      end
      """
      @spec all(
              Permit.Types.permissions(),
              Permit.Types.object_or_resource_module()
            ) :: Permit.Types.permissions()
      def all(authorization, resource),
        do: all(authorization, resource, true)
    end
  end
end
