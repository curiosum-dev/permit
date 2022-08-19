defmodule Permit do
  @moduledoc """
  Authorization facilities for the application.
  """
  defstruct role: nil, permissions: Permit.Permissions.new(), subject: nil

  alias Permit.Types
  alias Permit.Permissions
  alias Permit.HasRoles

  @type t :: %Permit{
          permissions: Permissions.t(),
          subject: Permit.HasRoles.t()
        }

  defmacro __using__(opts) do
    alias Permit.Types

    permissions_module = Keyword.fetch!(opts, :permissions_module)

    predicates =
      permissions_module
      |> Macro.expand(__CALLER__)
      |> apply(:actions_module, [])
      |> apply(:list_actions, [])
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
      def can(subject) do
        subject
        |> HasRoles.roles()
        |> Stream.map(fn role ->
          unquote(permissions_module).can(role)
        end)
        |> Enum.reduce(fn auth1, auth2 ->
          %Permit{auth1 | permissions: Permissions.join(auth1.permissions, auth2.permissions)}
        end)
        |> Permit.change_subject(subject)
      end

      # by default delete?, update?, read?, create?
      unquote(predicates)

      @spec do?(Permit.t(), Types.controller_action(), Types.resource()) :: boolean()
      def do?(authorization, action, resource) do
        Permit.verify_record(authorization, action, resource)
      end

      @spec repo() :: Ecto.Repo.t()
      def repo, do: unquote(opts[:repo])

      @spec accessible_by(Types.subject(), Types.controller_action(), Types.resource()) ::
              {:ok, Ecto.Query.t()} | {:error, term()}
      def accessible_by(current_user, action, resource) do
        unquote(permissions_module)
        |> apply(:can, [current_user])
        |> Map.get(:permissions)
        |> Permissions.construct_query(action, resource)
      end
    end
  end

  @spec change_subject(Permit.t(), Permit.HasRole.t()) :: Permit.t()
  def change_subject(authorization, subject) do
    %Permit{authorization | subject: subject}
  end

  @spec add_permission(Permit.t(), Types.controller_action(), Types.resource_module(), [
          Types.condition()
        ]) ::
          Permit.t()
  def add_permission(authorization, action, resource, conditions) when is_list(conditions) do
    updated_permissions =
      authorization.permissions
      |> Permissions.add(action, resource, conditions)

    %Permit{authorization | permissions: updated_permissions}
  end

  @spec verify_record(Permit.t(), Types.resource(), Types.controller_action()) :: boolean()
  def verify_record(authorization, record, action) do
    authorization.permissions
    |> Permissions.granted?(action, record, authorization.subject)
  end

  defp add_predicate_name(atom),
    do: {(Atom.to_string(atom) <> "?") |> String.to_atom(), atom}
end
