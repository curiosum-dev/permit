defmodule Permit do
  @moduledoc """
  Authorization facilities for the application.
  """
  defstruct role: nil, permissions: Permit.Permissions.new(), subject: nil

  alias Permit.Types
  alias Permit.Permissions

  @type t :: %Permit{
          role: Types.role(),
          permissions: Permissions.t(),
          subject: Types.subject() | nil
        }

  defmacro __using__(opts) do
    alias Permit.Types

    permissions_module = Keyword.fetch!(opts, :permissions_module)

    quote do
      @doc """
      Initializes a structure holding permissions for a given user role.

      Returns a Permit struct.
      """

      @spec can(Types.subject_with_role()) :: Permit.t()
      def can(%{role: role} = subject) when is_struct(subject),
        do: can(role, subject)

      @spec can(Types.role_record(), Types.subject() | nil) :: Permit.t()
      def can(role, subject \\ nil)

      def can(role, nil) when is_map(role) do
        unquote(permissions_module).can(role)
      end

      def can(role, subject) when is_map(role) do
        can(role)
        |> Permit.put_subject(subject)
      end

      @spec read?(Permit.t(), Types.resource()) :: boolean()
      def read?(authorization, resource) do
        Permit.verify_record(authorization, resource, :read)
      end

      @spec create?(Permit.t(), Types.resource()) :: boolean()
      def create?(authorization, resource) do
        Permit.verify_record(authorization, resource, :create)
      end

      @spec update?(Permit.t(), Types.resource()) :: boolean()
      def update?(authorization, resource) do
        Permit.verify_record(authorization, resource, :update)
      end

      @spec delete?(Permit.t(), Types.resource()) :: boolean()
      def delete?(authorization, resource) do
        Permit.verify_record(authorization, resource, :delete)
      end

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

  @spec put_subject(Permit.t(), Types.role()) :: Permit.t()
  def put_subject(authorization, subject) do
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
end
