defmodule Permit.FakeApp.User do
  @moduledoc false
  defstruct [:id, :roles]

  defimpl Permit.HasRoles, for: Permit.FakeApp.User do
    def roles(user), do: user.roles
  end
end
