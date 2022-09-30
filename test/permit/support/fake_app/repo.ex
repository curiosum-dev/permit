defmodule Permit.FakeApp.Repo do
  use Ecto.Repo,
    otp_app: :permit,
    adapter: Ecto.Adapters.Postgres

  # def get(Item, "1"), do: @item1
  # def get(Item, 1), do: @item1
  # def get(Item, "2"), do: @item2
  # def get(Item, 2), do: @item2
  # def get(Item, "3"), do: @item3
  # def get(Item, 3), do: @item3
  # def get(Item, _), do: nil

  # def all(query) do
  #   IO.inspect(query)
  #   [@item1, @item2, @item3]
  # end
end
