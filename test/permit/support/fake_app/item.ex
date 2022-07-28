defmodule Permit.FakeApp.Item do
  defstruct [:id, :owner_id, :permission_level]

  def __schema__(:query), do: %Ecto.Query{}
end
