defmodule Permit.FakeApp.Repo do
  use Ecto.Repo,
    otp_app: :permit,
    adapter: Ecto.Adapters.Postgres

  # These functions used to be necessary back when the Repo was fake,
  # and not actually Postgres-backed.
  #
  # At that time, we would stub get/1, get/2 and all/1 functions
  # needed by preloader modules.

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
