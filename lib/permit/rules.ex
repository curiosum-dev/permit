defmodule Permit.Rules do
  @moduledoc """
  Provides functions used for defining the application's permission set.
  """
  alias Permit.Types
  alias __MODULE__

  defmacro __using__(opts) do
    actions_module =
      Keyword.get(
        opts,
        :actions_module,
        quote do
          Permit.Actions.CrudActions
        end
      )

    action_functions =
      actions_module
      |> Macro.expand(__CALLER__)
      |> apply(:list_groups, [])
      |> Enum.map(fn name ->
        quote do
          # @spec unquote(name)(Permit.t(), Types.resource(), Types.condition()) :: Permit.t()
          defmacro unquote(name)(authorization, resource, bindings, conditions) do
            action = unquote(name)

            quote do
              permission_to(
                unquote(authorization),
                unquote(action),
                unquote(resource),
                unquote(bindings),
                unquote(conditions)
              )
            end
          end

          @spec unquote(name)(Permit.t(), Types.resource(), Types.condition()) :: Permit.t()
          def unquote(name)(authorization, resource, conditions) do
            authorization
            |> Rules.permission_to(unquote(name), resource, conditions)
          end

          @spec unquote(name)(Permit.t(), Types.resource()) :: Permit.t()
          def unquote(name)(authorization, resource) do
            authorization
            |> Rules.permission_to(unquote(name), resource, true)
          end
        end
      end)

    quote do
      import Permit.Rules

      unquote(action_functions)

      defmacro all(authorization, resource, bindings, conditions) do
        quote do
          actions_module()
          |> apply(:list_groups, [])
          |> Enum.reduce(unquote(authorization), fn group, auth ->
            permission_to(auth, group, unquote(resource), unquote(bindings), unquote(conditions))
          end)
        end
      end

      def all(authorization, resource, conditions) do
        unquote(actions_module)
        |> apply(:list_groups, [])
        |> Enum.reduce(authorization, fn group, auth ->
          permission_to(auth, group, resource, conditions)
        end)
      end

      def all(authorization, resource),
        do: all(authorization, resource, true)

      def actions_module,
        do: unquote(actions_module)
    end
  end

  @spec grant(Types.role()) :: Permit.t()
  def grant(role), do: %Permit{roles: [role]}

  def unify_conditions(bindings, condition) when not is_list(condition) do
    unify_conditions(bindings, [condition])
  end

  def unify_conditions(bindings, conditions) do
    conditions
    |> Enum.map(&Permit.parse_condition(&1, bindings))
  end

  defmacro permission_to(authorization, action_group, resource, bindings, conditions) do
    binds =
      bindings
      |> Enum.map(&elem(&1, 0))
      |> Macro.escape()

    conditions =
      conditions
      |> Macro.escape()

    quote do
      unquote(authorization)
      |> Permit.add_permission(
        unquote(action_group),
        unquote(resource),
        unify_conditions(unquote(binds), unquote(conditions))
      )
    end
  end

  def permission_to(authorization, action_group, resource, conditions) do
    authorization
    |> Permit.add_permission(
      action_group,
      resource,
      unify_conditions([], conditions)
    )
  end

  def permission_to(authorization, action_group, resource),
    do: permission_to(authorization, action_group, resource, true)
end
