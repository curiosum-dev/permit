defmodule Permit.ControllerAuthorization do
  @moduledoc """
  Injects authorization plug (Permit.Plug), allowing to
  provide its options either directly in options of `use`, or
  as overridable functions.

  Example:

      # my_app_web.ex
      def controller do
        use Permit.ControllerAuthorization,
          authorization_module: MyApp.Authorization,
          fallback_path: "/unauthorized"
      end

      # your controller module
      defmodule MyAppWeb.PageController do
        use MyAppWeb, :live_view

        @impl true
        def resource_module, do: MyApp.Item

        # you might or might not want to override something here
        @impl true
        def fallback_path: "/foo"
      end

  """
  alias Permit.Types
  alias Permit.FakeApp.Item.Context

  @callback authorization_module() :: module()
  @callback resource_module() :: module()
  @callback prefilter(Types.controller_action(), module(), map()) :: Ecto.Query.t()
  @callback postfilter(Ecto.Query.t()) :: Ecto.Query.t()
  @callback handle_unauthorized(Types.conn()) :: Types.conn()
  @callback user_from_conn(Types.conn()) :: struct()
  @callback preload_resource_in() :: list(atom())
  @callback fallback_path() :: binary()
  @callback except() :: list(atom())
  @callback preload(Types.controller_action(), Types.resource_module(), Types.subject(), map()) :: any()
  @optional_callbacks handle_unauthorized: 1,
                      preload_resource_in: 0,
                      fallback_path: 0,
                      resource_module: 0,
                      except: 0,
                      prefilter: 3,
                      postfilter: 1,
                      user_from_conn: 1,
                      preload: 4


  defmacro __using__(opts) do
    opts_authorization_module =
      opts[:authorization_module] ||
        raise(":authorization_module option must be given when using ControllerAuthorization")

    opts_resource_module = opts[:resource_module]
    opts_preload_resource_in = opts[:preload_resource_in]
    opts_fallback_path = opts[:fallback_path]
    opts_except = opts[:except]
    preload = opts[:preload_fn]

    opts_id_param_name =
      Keyword.get(
        opts,
        :id_param_name,
        quote do
          "id"
        end
      )

    opts_id_struct_field_name =
      Keyword.get(
        opts,
        :id_struct_name,
        quote do
          :id
        end
      )

    opts_user_from_conn_fn = opts[:user_from_conn]

    quote generated: true do
      require Logger
      require Ecto.Query
      import Ecto.Query

      @behaviour unquote(__MODULE__)

      @impl true
      def handle_unauthorized(conn) do
        conn
        |> put_flash(
          :error,
          unquote(opts[:error_msg]) || "You do not have permission to perform this action."
        )
        |> redirect(to: unquote(opts_fallback_path))
        |> halt()
      end

      @impl true
      def authorization_module, do: unquote(opts_authorization_module)

      @impl true
      def resource_module, do: unquote(opts_resource_module)

      @impl true
      def preload_resource_in do
        preload_resource_in = unquote(opts_preload_resource_in)

        case preload_resource_in do
          nil -> [:show, :edit, :update, :delete]
          list when is_list(list) -> list ++ [:show, :edit, :update, :delete]
        end
      end

      @impl true
      def fallback_path do
        fallback_path = unquote(opts_fallback_path)

        case fallback_path do
          nil -> "/"
          _ -> fallback_path
        end
      end

      @impl true
      def except do
        except = unquote(opts_except)

        case except do
          nil -> []
          _ -> except
        end
      end

      @impl true
      def prefilter(_action, resource_module, %{unquote(opts_id_param_name) => id}) do
        resource_module
        |> Context.filter_by_field(unquote(opts_id_struct_field_name), id)
      end

      def prefilter(_action, resource_module, _params), do: from r in resource_module

      @impl true
      def postfilter(query), do: query

      @impl true
      def user_from_conn(conn) do
        user_from_conn_fn = unquote(opts_user_from_conn_fn)

        cond do
          is_function(user_from_conn_fn, 1) ->
            user_from_conn_fn.(conn)

          true ->
            conn.assigns[:current_user]
        end
      end

      defoverridable handle_unauthorized: 1,
                     preload_resource_in: 0,
                     fallback_path: 0,
                     resource_module: 0,
                     except: 0,
                     user_from_conn: 1

      plug(Permit.Plug,
        authorization_module: &__MODULE__.authorization_module/0,
        resource_module: &__MODULE__.resource_module/0,
        preload_resource_in: &__MODULE__.preload_resource_in/0,
        fallback_path: &__MODULE__.fallback_path/0,
        except: &__MODULE__.except/0,
        prefilter: &__MODULE__.prefilter/3,
        postfilter: &__MODULE__.postfilter/1,
        user_from_conn: &__MODULE__.user_from_conn/1,
        handle_unauthorized: &__MODULE__.handle_unauthorized/1,
        preload_fn: unquote(preload)
      )
    end
  end
end
