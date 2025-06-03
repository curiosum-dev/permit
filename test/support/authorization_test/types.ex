defmodule Permit.AuthorizationTest.Types do
  @moduledoc false
  defmodule TestUser do
    @moduledoc false

    defstruct [:id, :role, :overseer_id, :some_string]

    defimpl Permit.SubjectMapping, for: Permit.AuthorizationTest.Types.TestUser do
      def subjects(user), do: [user.role]
    end
  end

  defmodule TestUserAsRole do
    @moduledoc false

    defstruct [:id, :role, :overseer_id]

    defimpl Permit.SubjectMapping, for: Permit.AuthorizationTest.Types.TestUserAsRole do
      def subjects(user), do: [user]
    end
  end

  defmodule TestObject do
    @moduledoc false
    defstruct [:id, :name, :owner_id, :manager_id, :field_2, field_1: 0]
  end
end
