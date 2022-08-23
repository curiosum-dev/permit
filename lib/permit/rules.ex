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
      |> apply(:list_actions, [])
      |> Enum.map(fn name ->
        quote do
          @spec unquote(name)(Permit.t(), Types.resource(), Types.condition()) :: boolean()
          def unquote(name)(authorization, resource, conditions \\ true) do
            case unquote(actions_module).include_crud_mapping() do
              true -> [unquote(name) | unquote(actions_module).mappings()[unquote(name)]]
              false -> [unquote(name)]
            end
            |> Enum.uniq()
            |> Enum.reduce(authorization, fn action, perm ->
              permission_to(perm, action, resource, conditions)
            end)
          end
        end
      end)

    quote do
      import Permit.Rules

      unquote(action_functions)

      def all(authorization, resource, conditions \\ true) do
        unquote(actions_module)
        |> apply(:list_actions, [])
        |> Enum.reduce(authorization, fn action, auth ->
          apply(__MODULE__, action, [auth, resource, conditions])
        end)
      end

      def actions_module,
        do: unquote(actions_module)
    end
  end

  @spec grant(Types.role() | [Types.role()]) :: Permit.t()
  def grant(role), do: %Permit{role: role}

  def permission_to(authorization, action, resource, conditions \\ true),
    do: put_action(authorization, action, resource, conditions)

  defp put_action(authorization, action, resource, condition)
       when not is_list(condition) do
    authorization
    |> put_action(action, resource, [condition])
  end

  defp put_action(authorization, action, resource, conditions) do
    authorization
    |> Permit.add_permission(action, resource, conditions)
  end
end
