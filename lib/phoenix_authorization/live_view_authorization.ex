defmodule PhoenixAuthorization.LiveViewAuthorization do
  @moduledoc """
  A live view module using the authorization mechanism should mix in the LiveViewAuthorization
  module:

      defmodule MyAppWeb.DocumentLive.Index
        use PhoenixAuthorization.LiveViewAuthorization
      end

  which adds the LiveViewAuthorization behavior with the following callbacks to be implemented -
  for example:

      # The related schema
      @impl true
      def resource_module, do: Document

      # Loader function for a singular resource in appropriate actions (:show, etc.); usually a context
      # function. If not defined, Repo.get is used by default.
      @impl true
      def loader_fn, do: fn id -> get_organization!(id) end

      # How to fetch the current user from session - for instance:
      @impl true
      def user_from_session(session) do
        with token when not is_nil(token) <- session["token"],
             %User{} = current_user <- get_user(token) do
          current_user
        else
          _ -> nil
        end
      end

  Optionally, a handle_unauthorized/2 optional callback can be implemented, returning {:cont, socket}
  or {:halt, redirect}. The default implementation returns:

      {:halt, push_redirect(socket, to: socket.view.fallback_path())}
  """
  alias PhoenixAuthorization.Types

  @callback resource_module() :: module()
  @callback loader_fn() :: fun()
  @callback handle_unauthorized(Types.socket()) :: Types.hook_outcome()
  @callback user_from_session(map()) :: struct()
  @callback authorization_module() :: module()
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
                      id_param_name: 0

  defmacro __using__(opts) do
    authorization_module =
      opts[:authorization_module] ||
        raise(":authorization_module option must be given when using LiveViewAuthorization")

    resource_module = opts[:resource_module]
    preload_resource_in = opts[:preload_resource_in]
    action_crud_mapping = opts[:action_crud_mapping]
    fallback_path = opts[:fallback_path]
    except = opts[:except]
    id_param_name = opts[:id_param_name]

    quote do
      @behaviour unquote(__MODULE__)

      @impl true
      def handle_unauthorized(socket) do
        {:halt, push_redirect(socket, to: fallback_path())}
      end

      @impl true
      def authorization_module, do: unquote(authorization_module)

      @impl true
      def resource_module, do: unquote(resource_module)

      @impl true
      def preload_resource_in, do: (unquote(preload_resource_in) || []) ++ [:show, :edit]

      @impl true
      def fallback_path, do: unquote(fallback_path) || "/"

      @impl true
      def except, do: unquote(except) || []

      @impl true
      def action_crud_mapping, do: unquote(action_crud_mapping) || []

      @impl true
      def id_param_name, do: unquote(id_param_name) || "id"

      defoverridable handle_unauthorized: 1,
                     preload_resource_in: 0,
                     fallback_path: 0,
                     resource_module: 0,
                     except: 0,
                     action_crud_mapping: 0,
                     id_param_name: 0
    end
  end
end
