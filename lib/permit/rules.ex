defmodule Permit.Rules do
  @moduledoc """
  Provides functions used for defining the application's permission set.
  """
  alias Permit.Types

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
          defmacro unquote(name)(authorization, resource, conditions \\ true) do
            action = unquote(name)
            quote do
              permission_to(unquote(authorization), unquote(action), unquote(resource), unquote(conditions))
            end
          end
        end
      end)

    quote do
      import Permit.Rules

      unquote(action_functions)

      def all(authorization, resource, conditions \\ true) do
        unquote(actions_module)
        |> apply(:list_groups, [])
        |> Enum.reduce(authorization, fn group, auth ->
          permission_to(auth, group, resource, conditions)
        end)
      end

      def actions_module,
        do: unquote(actions_module)
    end
  end

  @spec grant(Types.role()) :: Permit.t()
  def grant(role), do: %Permit{roles: [role]}

  def permission_to(authorization, action_group, resource, conditions \\ true),
    do: put_group(authorization, action_group, resource, conditions)

  defp put_group(authorization, action_group, resource, condition)
       when not is_list(condition) do
    authorization
    |> put_group(action_group, resource, [condition])
  end

  defp put_group(authorization, action_group, resource, conditions) do
    authorization
    |> Permit.add_permission(action_group, resource, conditions)
  end
end
