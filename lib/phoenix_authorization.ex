defmodule PhoenixAuthorization do
  @moduledoc """
  Authorization facilities for the application.
  """

  # create: %{}, read: %{}, update: %{}, delete: %{}
  defstruct role: nil, condition_lists: []

  alias PhoenixAuthorization.Types

  @type t :: %PhoenixAuthorization{role: Types.role(), condition_lists: [list()]}

  defmacro __using__(opts) do
    alias PhoenixAuthorization.Types

    permissions_module = Keyword.fetch!(opts, :permissions_module)

    quote do
      @doc """
      Initializes a structure holding permissions for a given user role.

      Returns a PhoenixAuthorization struct.
      """

      @spec can(Types.role_record(), Types.subject() | nil) :: PhoenixAuthorization.t()
      def can(role, subject \\ nil)

      def can(role, nil) when is_map(role) do
        unquote(permissions_module).can(role)
      end

      def can(role, subject) when is_map(role) do
        can(role)
        |> PhoenixAuthorization.put_subject(subject)
      end

      @spec read?(struct(), any()) :: boolean()
      def read?(authorization, resource) do
        condition_lists =
          PhoenixAuthorization.condition_lists_for_action(authorization, :read, resource)

        PhoenixAuthorization.verify_record(authorization, resource, condition_lists)
      end

      @spec create?(struct(), any()) :: boolean()
      def create?(authorization, resource) do
        condition_lists =
          PhoenixAuthorization.condition_lists_for_action(authorization, :create, resource)

        PhoenixAuthorization.verify_record(authorization, resource, condition_lists)
      end

      @spec update?(struct(), any()) :: boolean()
      def update?(authorization, resource) do
        condition_lists =
          PhoenixAuthorization.condition_lists_for_action(authorization, :update, resource)

        PhoenixAuthorization.verify_record(authorization, resource, condition_lists)
      end

      @spec delete?(struct(), any()) :: boolean()
      def delete?(authorization, resource) do
        condition_lists =
          PhoenixAuthorization.condition_lists_for_action(authorization, :delete, resource)

        PhoenixAuthorization.verify_record(authorization, resource, condition_lists)
      end

      @spec repo() :: Ecto.Repo.t()
      def repo, do: unquote(opts[:repo])
    end
  end

  @spec condition_lists_for_action(PhoenixAuthorization.t(), Types.crud(), Types.resource()) :: [
          list()
        ]
  def condition_lists_for_action(authorization, action, resource) do
    resource_module =
      case resource do
        %struct_module{} ->
          struct_module

        other_atom ->
          other_atom
      end

    authorization.condition_lists
    |> Enum.filter(fn {a, _} -> a == action end)
    |> Enum.map(fn {_, struct_condlist_mapping} ->
      struct_condlist_mapping[resource_module]
    end)
    |> Enum.reject(&is_nil(&1))
  end

  def put_subject(authorization, subject) do
    Map.put(authorization, :subject, subject)
  end

  def verify_record(authorization, record, condition_lists) do
    condition_lists
    |> Enum.any?(&conditions_satisfied?(authorization, record, &1))
  end

  # Empty condition set means that an authorization subject is not authorized
  # to interact with a given record.
  defp conditions_satisfied?(_authorization, _record, []), do: false

  defp conditions_satisfied?(_authorization, _record, true), do: true

  defp conditions_satisfied?(_authorization, module, conditions) when is_atom(module) do
    conditions
    |> Enum.all?(&(!!&1))
  end

  defp conditions_satisfied?(authorization, record, conditions) when is_struct(record) do
    conditions
    |> Enum.all?(fn
      {field, expected_value} ->
        actual = Map.get(record, field)
        expected_value == actual

      function when is_function(function, 1) ->
        !!function.(record)

      function when is_function(function, 2) ->
        !!function.(authorization.subject, record)
    end)
  end
end
