defmodule PhoenixAuthorization.ControllerAuthorization do
  alias PhoenixAuthorization.Types

  @callback authorization_module() :: module()
  @callback resource_module() :: module()
  @callback loader_fn() :: fun() | nil
  @callback handle_unauthorized(Types.conn()) :: Types.conn()
  @callback user_from_conn(Types.conn()) :: struct() | nil
  @callback preload_resource_in() :: list(atom())
  @callback fallback_path() :: binary()
  @callback action_crud_mapping() :: keyword(Types.crud())
  @callback except() :: list(atom())
  @callback id_param_name() :: Types.id_param_name()

  @optional_callbacks handle_unauthorized: 1,
                      preload_resource_in: 0,
                      fallback_path: 0,
                      action_crud_mapping: 0,
                      resource_module: 0,
                      except: 0,
                      loader_fn: 0,
                      id_param_name: 0,
                      user_from_conn: 1

  defmacro __using__(opts) do
    authorization_module =
      opts[:authorization_module] ||
        raise(":authorization_module option must be given when using ControllerAuthorization")

    resource_module = opts[:resource_module]
    preload_resource_in = opts[:preload_resource_in]
    action_crud_mapping = opts[:action_crud_mapping]
    fallback_path = opts[:fallback_path]
    except = opts[:except]
    id_param_name = opts[:id_param_name]
    loader_fn = opts[:loader_fn]
    user_from_conn_fn = opts[:user_from_conn]

    quote do
      require Logger

      @behaviour unquote(__MODULE__)

      @impl true
      def handle_unauthorized(conn) do
        conn
        |> put_flash(
          :error,
          unquote(opts[:error_msg]) || "You do not have permission to perform this action."
        )
        |> redirect(to: unquote(fallback_path))
        |> halt()
      end

      @impl true
      def authorization_module, do: unquote(authorization_module)

      @impl true
      def resource_module, do: unquote(resource_module)

      @impl true
      def preload_resource_in,
        do: (unquote(preload_resource_in) || []) ++ [:show, :edit, :update, :delete]

      @impl true
      def fallback_path, do: unquote(fallback_path) || "/"

      @impl true
      def except, do: unquote(except) || []

      @impl true
      def action_crud_mapping, do: unquote(action_crud_mapping) || []

      @impl true
      def id_param_name, do: unquote(id_param_name) || "id"

      @impl true
      def loader_fn, do: unquote(loader_fn)

      @impl true
      def user_from_conn(conn) do
        user_from_conn_fn = unquote(user_from_conn_fn)

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
                     action_crud_mapping: 0,
                     id_param_name: 0,
                     user_from_conn: 1

      plug(PhoenixAuthorization.Plug,
        authorization_module: &__MODULE__.authorization_module/0,
        resource_module: &__MODULE__.resource_module/0,
        preload_resource_in: &__MODULE__.preload_resource_in/0,
        action_crud_mapping: &__MODULE__.action_crud_mapping/0,
        fallback_path: &__MODULE__.fallback_path/0,
        except: &__MODULE__.except/0,
        loader_fn: &__MODULE__.loader_fn/0,
        id_param_name: &__MODULE__.id_param_name/0,
        user_from_conn: &__MODULE__.user_from_conn/1,
        handle_unauthorized: &__MODULE__.handle_unauthorized/1
      )
    end
  end
end
