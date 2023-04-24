defmodule Permit.RuleSyntax do
  @moduledoc """
  Provides functions used for defining the application's permission set.
  """
  alias Permit.Types
  alias Permit.Permissions.ParsedCondition

  defmacro __using__(opts) do
    actions_module =
      Keyword.get(
        opts,
        :actions_module,
        quote do
          Permit.Actions.CrudActions
        end
      )

    permission_macro =
      quote do
        defmacro permission_to(authorization, action_group, resource, bindings, conditions) do
          escaped_bindings =
            bindings
            |> Enum.map(&elem(&1, 0))
            |> Macro.escape()

          escaped_conditions =
            conditions
            |> Macro.escape()

          quote do
            unquote(authorization)
            |> __MODULE__.add_permission(
              unquote(action_group),
              unquote(resource),
              unquote(escaped_bindings),
              unquote(escaped_conditions)
            )
          end
        end
      end

    # Named action functions
    action_functions =
      actions_module
      |> Macro.expand(__CALLER__)
      |> apply(:list_groups, [])
      |> Enum.map(fn name ->
        quote do
          defmacro unquote(name)(authorization, resource, bindings, conditions) do
            action = unquote(name)

            # bindings = Macro.escape(bindings)
            # conditions = Macro.escape(conditions)

            escaped_bindings =
              bindings
              |> Enum.map(&elem(&1, 0))
              |> Macro.escape()

            escaped_conditions =
              conditions
              |> Macro.escape()

            quote do
              unquote(authorization)
              |> __MODULE__.add_permission(
                unquote(action),
                unquote(resource),
                # unquote(bindings),
                # unquote(conditions)
                unquote(escaped_bindings),
                unquote(escaped_conditions)
              )
            end
          end

          @spec unquote(name)(Permit.t(), Types.resource(), Types.condition()) :: Permit.t()
          def unquote(name)(authorization, resource, conditions) do
            authorization
            |> __MODULE__.permission_to(unquote(name), resource, conditions)
          end

          @spec unquote(name)(Permit.t(), Types.resource()) :: Permit.t()
          def unquote(name)(authorization, resource) do
            authorization
            |> __MODULE__.permission_to(unquote(name), resource, true)
          end
        end
      end)

    quote do
      import Permit.RuleSyntax

      alias Permit.Permissions.ParsedCondition
      alias Permit.Types

      # defdelegate parse_conditions(bindings, conditions, decorate_condition),
      #   to: unquote(__MODULE__)

      # defoverridable parse_conditions: 3

      @spec add_permission(
              Permit.t(),
              Types.action_group(),
              Types.resource_module(),
              list(),
              Types.condition()
            ) ::
              Permit.t()
      def add_permission(authorization, action, resource, bindings, conditions) do
        parsed_conditions =
          Permit.RuleSyntax.parse_conditions(
            bindings,
            conditions,
            unquote(opts[:condition_decorator]) || (& &1)
          )

        authorization.permissions
        |> Permit.Permissions.add(action, resource, parsed_conditions)
        |> then(&%Permit{authorization | permissions: &1})
      end

      def permission_to(authorization, action_group, resource, conditions) do
        authorization
        |> __MODULE__.add_permission(
          action_group,
          resource,
          [],
          conditions
        )
      end

      def permission_to(authorization, action_group, resource),
        do: permission_to(authorization, action_group, resource, true)

      unquote(permission_macro)

      unquote(action_functions)

      defmacro all(authorization, resource, bindings, conditions) do
        escaped_bindings =
          bindings
          |> Enum.map(&elem(&1, 0))
          |> Macro.escape()

        escaped_conditions =
          conditions
          |> Macro.escape()

        quote do
          actions_module()
          |> apply(:list_groups, [])
          |> Enum.reduce(unquote(authorization), fn group, auth ->
            auth
            |> __MODULE__.add_permission(
              group,
              unquote(resource),
              unquote(escaped_bindings),
              unquote(escaped_conditions)
            )
          end)
        end
      end

      def all(authorization, resource, conditions) do
        unquote(actions_module)
        |> apply(:list_groups, [])
        |> Enum.reduce(authorization, fn group, auth ->
          __MODULE__.permission_to(auth, group, resource, conditions)
        end)
      end

      def all(authorization, resource),
        do: all(authorization, resource, true)

      def actions_module,
        do: unquote(actions_module)

      @spec grant(Types.role()) :: Permit.t()
      def grant(role), do: %Permit{roles: [role]}
    end
  end

  def parse_condition(condition, bindings) when length(bindings) <= 2 do
    condition
    |> ParsedCondition.build(bindings: bindings)
  end

  def parse_condition(_condition, bindings) do
    raise "Binding list should have at most 2 elements (subject and object), Given #{inspect(bindings)}"
  end

  def parse_conditions(bindings, condition, decorate_condition) when not is_list(condition) do
    parse_conditions(bindings, [condition], decorate_condition)
  end

  def parse_conditions(bindings, raw_conditions, decorate_condition) do
    raw_conditions
    |> Enum.map(&(&1 |> __MODULE__.parse_condition(bindings) |> decorate_condition.()))
  end
end
