defmodule PhoenixAuthorization.FakeApp.User do
  @moduledoc false
  @behaviour PhoenixAuthorization.HasRoles

  defstruct [:id, :roles]

  @impl PhoenixAuthorization.HasRoles
  def roles(user), do: user.roles
end
