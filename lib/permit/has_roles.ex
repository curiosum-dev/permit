defprotocol Permit.HasRoles do
  @moduledoc """
  This protocol must be implemented by each module representing an authorization subject
  (usually this means an Ecto.Schema module for a User).

  The roles/1 callback must return a list of maps or structs matching the Types.role/record()
  contract - each item must have the :role field and may optionally have other fields denoting
  various metadata.

  Example:

      defmodule User do
        use Ecto.Schema

        @behaviour Permit.HasRoles

        schema "users" do
          # UserRole is an embedded_schema like:
          #     %UserRole{role: :user, org_id: 1}
          embeds_many :roles, UserRole
        end

        @impl Permit.HasRoles
        def roles(user), do: user.roles
      end
  """
  def roles(subject)
end
