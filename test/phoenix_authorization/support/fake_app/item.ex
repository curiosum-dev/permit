defmodule PhoenixAuthorization.FakeApp.Item do
  defstruct [:id, :owner_id]

  def __schema__(:query), do: %Ecto.Query{}
end
