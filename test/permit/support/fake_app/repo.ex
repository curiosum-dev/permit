defmodule Permit.FakeApp.Repo do
  use Ecto.Repo,
    otp_app: :permit,
    adapter: Ecto.Adapters.Postgres

  alias Permit.FakeApp.{User, Item, Repo}

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

  def seed_data! do
    users = [
      %User{id: 1} |> Repo.insert!(),
      %User{id: 2} |> Repo.insert!(),
      %User{id: 3} |> Repo.insert!()
    ]

    items = [
      %Item{id: 1, owner_id: 1, permission_level: 1} |> Repo.insert!(),
      %Item{id: 2, owner_id: 2, permission_level: 2, thread_name: "dmt"} |> Repo.insert!(),
      %Item{id: 3, owner_id: 3, permission_level: 3} |> Repo.insert!()
    ]

    %{users: users, items: items}
  end
end
