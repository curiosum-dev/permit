defmodule Permit.LiveViewAuthorization do
  @moduledoc """
  A live view module using the authorization mechanism should mix in the LiveViewAuthorization
  module:

      defmodule MyAppWeb.DocumentLive.Index
        use Permit.LiveViewAuthorization
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
  or {:halt, socket}. The default implementation returns:

      {:halt, socket(socket, to: socket.view.fallback_path())}
  """
  alias Permit.Types

  @callback resource_module() :: module()
  @callback loader_fn() :: fun()
  @callback handle_unauthorized(Types.socket()) :: Types.hook_outcome()
  @callback user_from_session(map()) :: struct()
  @callback authorization_module() :: module()
  @callback preload_resource_in() :: list(atom())
  @callback fallback_path() :: binary()
  @callback except() :: list(atom())
  @callback id_param_name() :: Types.id_param_name()
  @optional_callbacks handle_unauthorized: 1,
                      preload_resource_in: 0,
                      fallback_path: 0,
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
    fallback_path = opts[:fallback_path]
    except = opts[:except]
    id_param_name = opts[:id_param_name]

    quote do
      import unquote(__MODULE__)

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
      def id_param_name, do: unquote(id_param_name) || "id"

      defoverridable handle_unauthorized: 1,
                     preload_resource_in: 0,
                     fallback_path: 0,
                     resource_module: 0,
                     except: 0,
                     id_param_name: 0
    end
  end

  @doc """
  Returns true if inside mount/1, false otherwise. Useful for distinguishing between
  rendering directly via router or being in a handle_params lifecycle.

  For example, a handle_unauthorized/1 implementation must redirect when halting during mounting,
  while it needn't redirect when halting during the handle_params lifecycle.

      @impl true
      def handle_unauthorized(socket) do
        if mounting?(socket) do
          {:halt, push_redirect(socket, to: "/foo")}
        else
          {:halt, assign(socket, :unauthorized, true)}
        end
      end
  """
  @spec mounting?(Types.socket()) :: boolean()
  def mounting?(socket) do
    try do
      Phoenix.LiveView.get_connect_info(socket, :uri)
      true
    rescue
      # Raises RuntimeError if outside mount/1 because connect_info only exists while mounting.
      # This allows us to distinguish between accessing directly from router or via e.g. handle_params.
      RuntimeError -> false
    end
  end
end
