defmodule Permit.AuthorizationTest.Types do
  defmodule TestUser do
    @moduledoc false

    defstruct [:id, :role, :overseer_id, :some_string]

    defimpl Permit.HasRoles, for: Permit.AuthorizationTest.Types.TestUser do
      def roles(user), do: [user.role]
    end
  end

  defmodule TestUserAsRole do
    @moduledoc false

    defstruct [:id, :role, :overseer_id]

    defimpl Permit.HasRoles, for: Permit.AuthorizationTest.Types.TestUserAsRole do
      def roles(user), do: [user]
    end
  end

  defmodule TestObject do
    @moduledoc false
    defstruct [:id, :name, :owner_id, :manager_id, :field_2, field_1: 0]
  end
end
