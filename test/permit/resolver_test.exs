defmodule Permit.ResolverTest do
  use ExUnit.Case, async: true

  defmodule Item do
    defstruct [:user_id]
  end

  defmodule User do
    defstruct [:id]
  end

  defmodule TestActions do
    @moduledoc false
    use Permit.Actions

    @impl Permit.Actions
    def grouping_schema do
      %{
        new: [:create],
        index: [:read],
        show: [:read],
        edit: [:update]
      }
      |> Map.merge(crud_grouping())
    end

    def singular_actions,
      do: [:show, :edit, :new]
  end

  defmodule TestPermissions do
    @moduledoc false
    use Permit.Permissions, actions_module: TestActions

    def can(user) do
      permit()
      |> all(Item, user_id: user.id)
      |> read(Item)
    end
  end

  defmodule TestAuthorization do
    use Permit, permissions_module: TestPermissions
  end

  describe "authorized?/4" do
    test """
    with action grouping, transitively authorizes the :index action when :read permission is given
    """ do
      Permit.Resolver.authorized?(
        %User{id: 1},
        TestAuthorization,
        %Item{user_id: 2},
        :index
      )
      |> assert()
    end
  end
end
