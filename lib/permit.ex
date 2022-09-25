defmodule Permit do
  @moduledoc """
  Authorization facilities for the application.
  """
  defstruct roles: [], permissions: Permit.Permissions.new(), subject: nil

  alias Permit.HasRoles
  alias Permit.Permissions
  alias Permit.Permissions.Condition
  alias Permit.Permissions.UndefinedConditionError
  alias Permit.Permissions.UnconvertibleConditionError
  alias Permit.Types

  @type t :: %Permit{
          roles: [Types.role()],
          permissions: Permissions.t(),
          subject: Types.subject() | nil
        }

  defmacro __using__(opts) do
    alias Permit.Types

    permissions_module = Keyword.fetch!(opts, :permissions_module)

    predicates =
      permissions_module
      |> Macro.expand(__CALLER__)
      |> apply(:actions_module, [])
      |> apply(:list_groups, [])
      |> Enum.map(&add_predicate_name/1)
      |> Enum.map(fn {predicate, name} ->
        quote do
          @spec unquote(predicate)(Permit.t(), Types.resource()) :: boolean()
          def unquote(predicate)(authorization, resource) do
            Permit.verify_record(authorization, resource, unquote(name))
          end
        end
      end)

    quote do
      @doc """
      Initializes a structure holding permissions for a given user role.

      Returns a Permit struct.
      """

      def actions_module,
        do: unquote(permissions_module).actions_module()

      @spec can(HasRoles.t()) :: Permit.t()
      def can(nil),
        do: raise("Unable to create permit authorization for nil role/user")

      def can(who) do
        who
        |> HasRoles.roles()
        |> Stream.map(fn role ->
          unquote(permissions_module).can(role)
        end)
        |> Enum.reduce(fn auth1, auth2 ->
          %Permit{auth1 | permissions: Permissions.join(auth1.permissions, auth2.permissions)}
        end)
        |> Map.put(:roles, HasRoles.roles(who))
        |> Map.put(:subject, (is_struct(who) && who) || nil)
      end

      unquote(predicates)

      @spec repo() :: Ecto.Repo.t()
      def repo, do: unquote(opts[:repo])

      @spec accessible_by(Types.subject(), Types.action_group(), Types.resource(), (Types.resource() -> Ecto.Query.t())) ::
              {:ok, Ecto.Query.t()} | {:error, term()}
      def accessible_by(current_user, action, resource, prefilter \\ & &1) do
        current_user
        |> can()
        |> Map.get(:permissions)
        |> Permissions.construct_query(action, resource, current_user, actions_module(), prefilter)
      end

      @spec accessible_by!(Types.subject(), Types.action_group(), Types.resource(), (Types.resource() -> Ecto.Query.t())) ::
              Ecto.Query.t()
      def accessible_by!(current_user, action, resource, prefilter \\ & &1) do
        case accessible_by(current_user, action, resource, prefilter) do
          {:ok, query} ->
            query

          {:error, {:undefined_condition, key}} ->
            raise UndefinedConditionError, key

          {:error, errors} ->
            raise UnconvertibleConditionError, errors
        end
      end
    end
  end



  @spec has_subject(Permit.t()) :: boolean()
  def has_subject(%Permit{subject: nil}), do: false
  def has_subject(%Permit{subject: _}), do: true

  @spec do?(Permit.t(), Types.action_group(), Types.resource()) :: boolean()
  def do?(authorization, action, resource) do
    Permit.verify_record(authorization, action, resource)
  end

  @spec add_permission(Permit.t(), Types.action_group(), Types.resource_module(), [
          Types.condition()
        ]) ::
          Permit.t()
  def add_permission(authorization, action, resource, conditions) when is_list(conditions) do
    authorization.permissions
    |> Permissions.add(action, resource, conditions)
    |> then(& %Permit{authorization | permissions: &1})
  end

  @spec verify_record(Permit.t(), Types.resource(), Types.action_group()) :: boolean()
  def verify_record(authorization, record, action) do
    authorization.permissions
    |> Permissions.granted?(action, record, authorization.subject)
  end

  def parse_condition(condition, []) do
    condition
    |> Condition.new()
  end

  def parse_condition(condition, bindings)
  when length(bindings) <= 2 do
    condition
    |> Condition.new(bindings: bindings)
  end

  def parse_condition(_condition, bindings) do
    raise "Binding list should have at most 2 elements (subject and object), Given #{inspect(bindings)}"
  end

  defp add_predicate_name(atom),
    do: {(Atom.to_string(atom) <> "?") |> String.to_atom(), atom}
end
