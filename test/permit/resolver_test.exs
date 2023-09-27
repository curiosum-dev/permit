defmodule Permit.ResolverTest do
  use Permit.Case, async: true

  defmodule Item do
    @moduledoc false
    defstruct [:user_id]
  end

  defmodule User do
    @moduledoc false
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

  defmacro permissions_module(do: block) do
    inferred_modname =
      with {test_name_atom, _} <- __CALLER__.function do
        test_name_atom |> Atom.to_string() |> Macro.camelize() |> String.to_atom()
      end

    quote do
      {_, m, _, _} =
        defmodule unquote(inferred_modname) do
          use Permit.Permissions, actions_module: TestActions

          unquote(block)
        end

      m
    end
  end

  def authorization_module(permmodname) do
    [{authmodname, _}] =
      Code.compile_quoted(
        quote do
          modname = :"#{unquote(permmodname)}Authorization"

          defmodule modname do
            use(Permit, permissions_module: unquote(permmodname))
          end
        end
      )

    authmodname
  end

  describe "authorized?/4, action_grouping" do
    test """
    does not authorize :index on Item when only a restricted :all permission is present
    """ do
      authorization_module =
        permissions_module do
          def can(user) do
            permit()
            |> all(Item, user_id: user.id)
          end
        end
        |> authorization_module()

      refute Permit.Resolver.authorized?(
               %User{id: 1},
               authorization_module,
               %Item{user_id: 2},
               :index
             )
    end

    test """
    does not authorize :index on Item when no permissions are present
    """ do
      authorization_module =
        permissions_module do
          def can(_user) do
            permit()
          end
        end
        |> authorization_module()

      refute Permit.Resolver.authorized?(
               %User{id: 1},
               authorization_module,
               %Item{user_id: 2},
               :index
             )
    end

    test """
    authorizes :index on Item when the condition overrides a more restricted :all permission
    """ do
      authorization_module =
        permissions_module do
          def can(user) do
            permit()
            |> all(Item, user_id: user.id)
            |> read(Item)
          end
        end
        |> authorization_module()

      assert Permit.Resolver.authorized?(
               %User{id: 1},
               authorization_module,
               %Item{user_id: 2},
               :index
             )
    end

    test """
    authorizes :index on Item when both a matching and non-matching condition exists
    """ do
      authorization_module =
        permissions_module do
          def can(user) do
            permit()
            |> index(Item, user_id: -1)
            |> index(Item, user_id: user.id)
          end
        end
        |> authorization_module()

      assert Permit.Resolver.authorized?(
               %User{id: 1},
               authorization_module,
               %Item{user_id: 1},
               :index
             )
    end
  end
end
