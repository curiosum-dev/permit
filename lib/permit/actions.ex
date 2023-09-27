defmodule Permit.Actions do
  @moduledoc ~S"""

  ## Overview

  The `Permit.Actions` behaviour defines an exhaustive set of actions that can be performed on resources in the business domain.

  Actions can be grouped using the `c:grouping_schema/0` callback, which is useful when the developer intends to define permissions that imply that multiple actions will be authorized. For instance, in the `Permit.Phoenix` library, granting the `:read` permission results in the `:index` and `:show` actions being authorized.

  Permit includes a predefined `Permit.Actions.CrudActions` module that defines four basic CRUD actions: `create`, `read`, `update` and `delete`.

  `Permit.Permissions` generates functions for each of defined CRUD action names, as shorthands to define permissions to perform them - as well as an `all` function to permit all possible actions.

  Moreover, the `c:singular_actions/0` callback can be implemented to declare which actions are of singular nature, and which are of plural nature - for instance, an `:index` action is typically plural and a `:show` action is typically singular. This means that if automatic preloading mechanisms are in place, `:index` will load many records, and `:show` will load a single record.

  ## Example

  For instance, to make an `:index` action separate from a `:read` action, you may define an additional `:open` action and define `:index` as requiring only `:read`, and `:show` as requiring both `:open` and `:read`.

      defmodule MyApp.Actions do
        use Permit.Actions

        @impl Permit.Actions
        def grouping_schema do
          crud_grouping() # Includes :create, :read, :update and :delete
          |> Map.merge(%{
            index: [:read],

            # This is a 'plain' action not dependent on any other one, i.e. permission to these can be assigned directly
            open: []

            # This indicates that for the :show action to be performed, the :read AND open permissions must be granted.
            show: [:read, :open]
          })
        end
      end

  Declaring permissions basing on defined actions:

      defmodule MyApp.Permissions do
        use Permit.Permissions, actions_module: MyApp.Actions

        # An admin will be able to perform all actions on Note
        def can(%User{role: :admin} = _user) do
          permit()
          |> all(Note)
        end

        # A user will be able
        def can(%User{id: user_id} = _user) do
          permit()
          |> read(Note)
          |> open(Note, user_id: user_id)
        end

        def can(_), do: permit()
      end

  """
  alias __MODULE__
  alias Permit.Actions.{Forest, Traversal}
  alias Permit.CycledDefinitionError
  alias Permit.Types
  alias Permit.UndefinedActionError

  @doc ~S"""
  Used for mapping business domain _actions_ to _conjunctions of permissions_ required to perform them.

  In the example below, granting `:read` and `:open` means that `:show` action can be performed. Note, though, that this is a one-way implication - `:show` permission can be granted, but it does not imply that `:read` or `:open` are granted.

  ## Example

      @impl Permit.Actions
      def grouping_schema do
        crud_grouping() # Includes :create, :read, :update and :delete
        |> Map.merge(%{
          index: [:read],

          # This is a 'plain' action not dependent on any other one, i.e. permission to these can be assigned directly
          open: []

          # This indicates that for the :show action to be performed, the :read AND :open permissions must be granted.
          show: [:read, :open]
        })
      end
  """
  @callback grouping_schema() :: %{Types.action_group() => [Types.action_group()]}

  @doc ~S"""
  Declares which actions are singular, and which are plural.

  For instance, an `:index` action is typically plural and a `:show` action is typically singular. This means that if automatic preloading mechanisms are in place, `:index` will load many records, and `:show` will load a single record.

  ## Example

      @impl Permit.Actions
      def singular_actions do
        crud_singular() ++ [:show, :open]
      end
  """
  @callback singular_actions() :: [Types.action_group()]

  defmacro __using__(_opts) do
    quote do
      @behaviour Actions

      @crud_grouping %{
        create: [],
        read: [],
        update: [],
        delete: []
      }

      @crud_singular [:create, :read, :update, :delete]
      @doc """
      Convenience function defining the basic CRUD (create, read, update, delete) actions.
      """
      def crud_grouping, do: @crud_grouping

      @doc """
      Convenience function returning actions that are singular in the most basic CRUD setup, in which case
      all of: `:create`, `:read`, `:update` and `:delete` are singular.
      """
      def crud_singular, do: @crud_singular

      @impl Actions
      def grouping_schema, do: crud_grouping()

      @impl Actions
      def singular_actions, do: crud_singular()

      defoverridable grouping_schema: 0,
                     singular_actions: 0
    end
  end

  @doc false
  @spec verify_transitively(
          module(),
          Types.action_group(),
          (Types.action_group() -> boolean())
        ) ::
          {:ok, boolean()}
          | {:error, :cycle, [Types.action_group()]}
          | {:error, :not_defined, Types.action_group()}
  def verify_transitively(actions_module, action, verify_fn) do
    value = verify_fn

    empty = fn _ -> false end
    conj = &Enum.all?/1
    disj = &Enum.any?/1

    traverse_actions(
      actions_module,
      action,
      value,
      empty,
      conj,
      disj
    )
  end

  @spec verify_transitively!(
          module(),
          Types.action_group(),
          (Types.action_group() -> boolean())
        ) :: boolean()
  @doc false
  def verify_transitively!(actions_module, action, verify_fn) do
    fn -> verify_transitively(actions_module, action, verify_fn) end
    |> maybe_raise_traversal_errors!(actions_module)
  end

  @doc false
  def traverse_actions(actions_module, action_name, value, _empty, conj, disj) do
    actions_module.grouping_schema()
    |> Forest.new()
    |> Traversal.traverse(
      action_name,
      value: value,
      conj: conj,
      disj: disj
    )
    |> then(&{:ok, &1})
  catch
    {:not_defined, action_name} ->
      {:error, :not_defined, action_name}

    {:cycle, trace} ->
      {:error, :cycle, trace}
  end

  @doc false
  def traverse_actions!(actions_module, action_name, value, empty, conj, disj) do
    fn -> traverse_actions(actions_module, action_name, value, empty, conj, disj) end
    |> maybe_raise_traversal_errors!(actions_module)
  end

  @doc false
  def list_groups(actions_module) do
    actions_module.grouping_schema()
    |> Forest.new()
    |> Forest.uniq_nodes_list()
  end

  defp maybe_raise_traversal_errors!(function, actions_module) do
    case function.() do
      {:ok, result} ->
        result

      {:error, :not_defined, action} ->
        raise UndefinedActionError, {action, actions_module}

      {:error, :cycle, trace} ->
        raise CycledDefinitionError, {trace, actions_module}
    end
  end
end
