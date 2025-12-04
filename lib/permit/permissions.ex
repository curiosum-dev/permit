defmodule Permit.Permissions do
  @moduledoc """
  Defines the application's permission set. When used with `Permit.Ecto`, one should use `Permit.Ecto.Permissions` instead of `Permit.Permissions`.

  The behaviour defines the `c:can/1` callback, which must be implemented for defining permissions for a given subject.

  The module's `__using__/1` macro creates functions for each action defined in the module specified as the macro's option, defaulting to `Permit.Actions.CrudActions`.

  ## Usage

  A very simple usage example:
  ```
  defmodule MyApp.Permissions do
    use Permit.Permissions

    @impl true
    def can(%MyApp.User{role: :admin}) do
      permit()
      |> all(Article)
    end

    def can(%MyApp.User{id: user_id}) do
      permit()
      |> read(Article)
      |> all(Article, author_id: user_id)
    end

    def can(_), do: permit()
  end
  ```

  ## Named action functions

  By default, Permit will generate actions functions for the 4 common CRUD actions. If you need further actions, you can define a custom actions module .and configure it in both your `Authorization` and your `Permissions` module. See `Permit.Actions` for more information.

  ```elixir
  defmodule MyApp.Permissions do
    # actions_module defaults to Permit.Actions.CrudActions.
    use Permit.Permissions, actions_module: MyApp.Actions
  ```

  Each action defined in the `:actions_module` results in a 2-, 3-, and 4-arity function being generated.

  For instance, if a `:read` action is defined, there are the following calls available to grant the `:read` permission on a given resource type:
  * `read/2` function - grants permission without additional conditions
  * `read/3` function - with conditions defined using keywords and operators (see below),
  * `read/4` macro - with conditions defined using keywords, operators and bindings (see below).

  ### Example

      def can(%User{id: user_id}) do
        permit()
        |> read(Article, author_id: user_id)
        |> vote(Article, vote_count: {:<=, 100})
        |> review(Article, [user, article], user.level >= article.level)
      end

  ## `permission_to` functions

  Instead of action names, if more convenient, `permission_to` can be used, and the action name passed as an argument.

  ### Example

      def can(%User{id: user_id}) do
        permit()
        |> permission_to(:read, Article, author_id: user_id)
        |> permission_to(:vote, Article, vote_count: {:<=, 100})
        |> permission_to(:review, Article, [user, article], user.level >= article.level)
      end

  ## `all` functions

  In order to grant the user permission to all defined actions, use the `all` functions.

  ### Example

      def can(%User{id: user_id}) do
        permit()
        |> all(Article, author_id: user_id)
        |> all(Article, vote_count: {:<=, 100})
        |> all(Article, [user, article], user.level >= article.level)
      end
  """

  alias Permit.Permissions.ConditionParser
  alias Permit.Permissions.ParsedCondition
  alias Permit.Permissions.DisjunctiveNormalForm, as: DNF
  alias Permit.Types

  import Permit.Helpers, only: [resource_module_from_resource: 1]

  defstruct conditions_map: %{}

  @type conditions_by_action_and_resource :: %{
          {Types.action_group(), Types.resource_module()} => DNF.t()
        }
  @type t :: %__MODULE__{conditions_map: conditions_by_action_and_resource()}

  @callback can(Permit.Types.subject()) :: Permit.Types.permissions()

  defmacro __using__(opts) do
    alias Permit.Permissions.ActionFunctions
    alias Permit.Permissions.PermissionTo

    condition_parser = opts[:condition_parser] || (&ConditionParser.build/2)
    condition_types_module = opts[:condition_types_module] || Permit.Types.ConditionTypes

    actions_module = Keyword.get(opts, :actions_module, Permit.Actions.CrudActions)

    # Unnamed action macro
    permission_to = PermissionTo.mixin(condition_parser, condition_types_module)

    # Named action functions
    action_functions =
      ActionFunctions.named_actions_mixin(
        actions_module,
        __CALLER__,
        condition_parser,
        condition_types_module
      )

    all_actions_mixin =
      ActionFunctions.all_actions_mixin(
        actions_module,
        condition_parser,
        condition_types_module
      )

    quote do
      @behaviour Permit.Permissions
      import Permit.Permissions

      alias Permit.Permissions.ParsedCondition
      alias Permit.Types

      unquote(permission_to)

      unquote(action_functions)

      unquote(all_actions_mixin)

      def actions_module, do: unquote(actions_module)

      @doc """
      Initializes a structure holding permissions for a given user role.

      Returns a Permit struct.
      """
      @spec permit() :: Types.permissions()
      def permit, do: %Permit.Permissions{}
    end
  end

  @doc false
  def add_permission(permissions, action, resource, bindings, conditions, condition_parser) do
    parsed_conditions =
      __MODULE__.parse_conditions(
        bindings,
        conditions,
        condition_parser
      )

    permissions
    |> __MODULE__.add(action, resource, parsed_conditions)
  end

  @doc false
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

  @doc false
  def parse_condition(condition, bindings, condition_parser) when length(bindings) <= 2 do
    condition_parser.(condition, bindings: bindings)
  end

  @doc false
  def parse_condition(_condition, bindings, _condition_parser) do
    raise "Binding list should have at most 2 elements (subject and object), Given #{inspect(bindings)}"
  end

  def parse_conditions(bindings, condition, condition_parser) when not is_list(condition) do
    parse_conditions(bindings, [condition], condition_parser)
  end

  def parse_conditions(bindings, raw_conditions, condition_parser) do
    # raw_conditions
    # |> Enum.map(
    #   &(&1
    #     |> __MODULE__.parse_condition(bindings)
    #     |> condition_parser.())
    # )

    raw_conditions
    |> Enum.map(&__MODULE__.parse_condition(&1, bindings, condition_parser))
  end

  @doc false
  @spec add(__MODULE__.t(), Types.action_group(), Types.resource_module(), [ParsedCondition.t()]) ::
          __MODULE__.t()
  def add(permissions, action, resource, conditions) do
    permissions.conditions_map
    |> Map.update({action, resource}, DNF.add_clauses(DNF.new(), conditions), fn dnf ->
      DNF.add_clauses(dnf, conditions)
    end)
    |> new()
  end

  @doc false
  @spec granted?(
          __MODULE__.t(),
          Types.action_group(),
          Types.object_or_resource_module(),
          Types.subject()
        ) ::
          boolean()
  def granted?(permissions, action, record, subject) do
    permissions
    |> dnf_for_action_and_record(action, record)
    |> DNF.any_satisfied?(record, subject)
  end

  @doc false
  @spec concatenate(__MODULE__.t(), __MODULE__.t()) :: __MODULE__.t()
  def concatenate(p1, p2) do
    Map.merge(p1.conditions_map, p2.conditions_map, fn
      _k, dnf1, dnf2 -> DNF.concatenate(dnf1, dnf2)
    end)
    |> then(&%__MODULE__{conditions_map: &1})
  end

  @doc false
  @spec new() :: __MODULE__.t()
  def new, do: %__MODULE__{}

  @spec new(conditions_by_action_and_resource()) :: __MODULE__.t()
  defp new(rca), do: %__MODULE__{conditions_map: rca}

  @doc false
  @spec dnf_for_action_and_record(
          __MODULE__.t(),
          Types.action_group(),
          Types.object_or_resource_module()
        ) ::
          DNF.t()
  defp dnf_for_action_and_record(permissions, action, resource) do
    resource_module = resource_module_from_resource(resource)

    permissions.conditions_map
    |> Map.get({action, resource_module}, DNF.new())
  end
end
