defmodule Permit.RuleSyntax do
  @moduledoc """
  Provides functions used for defining the application's permission set.
  """
  alias Permit.Types
  alias Permit.Permissions.ParsedCondition

  def add_permission(permissions, action, resource, bindings, conditions, decorator) do
    parsed_conditions =
      Permit.RuleSyntax.parse_conditions(
        bindings,
        conditions,
        decorator
      )

    permissions
    |> Permit.Permissions.add(action, resource, parsed_conditions)
  end

  def escape_bindings_and_conditions(bindings, conditions) do
    escaped_bindings =
      bindings
      |> Enum.map(&elem(&1, 0))
      |> Macro.escape()

    escaped_conditions =
      conditions
      |> Macro.escape()

    {escaped_bindings, escaped_conditions}
  end

  defmacro __using__(opts) do
    decorator = opts[:condition_decorator] || (&Function.identity/1)

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
          decorator = unquote(decorator)

          {escaped_bindings, escaped_conditions} =
            Permit.RuleSyntax.escape_bindings_and_conditions(bindings, conditions)

          quote do
            Permit.RuleSyntax.add_permission(
              unquote(authorization),
              unquote(action_group),
              unquote(resource),
              unquote(escaped_bindings),
              unquote(escaped_conditions),
              unquote(decorator)
            )
          end
        end
      end

    # Named action functions
    action_functions =
      Macro.expand(actions_module, __CALLER__).list_groups()
      |> Enum.map(fn name ->
        quote do
          defmacro unquote(name)(authorization, resource, bindings, conditions) do
            action = unquote(name)

            decorator = unquote(decorator)

            {escaped_bindings, escaped_conditions} =
              Permit.RuleSyntax.escape_bindings_and_conditions(bindings, conditions)

            quote do
              Permit.RuleSyntax.add_permission(
                unquote(authorization),
                unquote(action),
                unquote(resource),
                unquote(escaped_bindings),
                unquote(escaped_conditions),
                unquote(decorator)
              )
            end
          end

          @spec unquote(name)(Permit.t(), Types.resource(), Types.condition()) :: Permit.t()
          def unquote(name)(authorization, resource, conditions)
              when is_list(conditions) do
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

      def permission_to(authorization, action_group, resource, conditions) do
        Permit.RuleSyntax.add_permission(
          authorization,
          action_group,
          resource,
          [],
          conditions,
          unquote(decorator)
        )
      end

      unquote(permission_macro)

      unquote(action_functions)

      defmacro all(authorization, resource, bindings, conditions) do
        decorator = unquote(decorator)

        {escaped_bindings, escaped_conditions} =
          Permit.RuleSyntax.escape_bindings_and_conditions(bindings, conditions)

        quote do
          actions_module().list_groups()
          |> Enum.reduce(unquote(authorization), fn group, auth ->
            Permit.RuleSyntax.add_permission(
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

      def all(authorization, resource, conditions) do
        unquote(actions_module).list_groups()
        |> Enum.reduce(authorization, fn group, auth ->
          __MODULE__.permission_to(auth, group, resource, conditions)
        end)
      end

      def all(authorization, resource),
        do: all(authorization, resource, true)

      def actions_module,
        do: unquote(actions_module)

      @spec permit() :: Permit.Permissions.t()
      def permit(), do: %Permit.Permissions{}
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
    |> Enum.map(
      &(&1
        |> __MODULE__.parse_condition(bindings)
        |> decorate_condition.())
    )
  end
end
