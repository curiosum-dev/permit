defprotocol Permit.SubjectMapping do
  @moduledoc """
  Allows mapping subject structure into one or more distinct subject records to denote that _any_ of these must be authorized to perform an action.

  Default mapping (implementation for `Any`) returns `[subject]` for a given `subject`, so all permissions will be checked against a single subject structure.

  Example - scenario of a multi-user session, in which any signed-in user must have permissions for authorization to be granted:
  ```elixir
  defmodule User, do: defstruct id: 1, name: "foo", role:
  defmodule UserSession,
    do: defstruct session_id: 1, current_users: []

  defimpl Permit.SubjectMapping, for: UserSession do
    def subjects(%UserSession{current_users: current_users}) do
      current_users
    end
  end

  defmodule Permissions do
    use Permit.Ecto.RuleSyntax, actions_module: Permit.Actions.CrudActions

    def can(%User{role: :reader} = user), do: permit()
    def can(%User{role: :auditor} = user), do: permit()
  end

  defmodule Authorization, do: use Permit, permissions_module: Permissions
  ```

  iex(1)> Authorization.can(%UserSession{users: [%User{role: :reader}, %User{role: :auditor}]})
  iex(2)> |> Authorization.update?(%Article{})
  true
  """

  alias Permit.Types

  @fallback_to_any true

  @spec subjects(Types.subject()) :: list(Types.subject())
  def subjects(subject)
end
