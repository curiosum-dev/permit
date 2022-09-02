defmodule Permit.FakeApp.Item.Context do
  import Ecto.Query
  alias Permit.FakeApp.Item
  alias Permit.FakeApp.Repo

  def filter_by_id(query, id) do
    query
    |> where([it], it.id == ^id)
  end

  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end
end
