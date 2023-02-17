defmodule Permit.FakeApp.Item.Context do
  import Ecto.Query
  alias Permit.FakeApp.Item
  alias Permit.FakeApp.Repo

  def filter_by_id(query, id) do
    query
    |> where([it], it.id == ^id)
  end

  def filter_by_field(query, field_name, value) do
    query
    |> where([it], field(it, ^field_name) == ^value)
  end

  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end
end
