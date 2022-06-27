defmodule Permit.FakeApp.User do
  @moduledoc false
  @behaviour Permit.HasRoles

  defstruct [:id, :roles]

  @impl Permit.HasRoles
  def roles(user), do: user.roles
end
