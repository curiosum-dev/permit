defmodule Permit.Types do
  @type resource_module :: module()
  @type controller_action :: atom()
  @type crud :: :create | :read | :update | :delete
  @type action_group :: atom()
  @type role :: term()
  @type subject :: struct()
  @type resource :: struct() | resource_module()
  @type id :: integer() | binary()
  @type id_param_name :: binary()
  @type loader :: (id() -> struct() | nil)
  @type socket :: Phoenix.LiveView.Socket.t()
  @type conn :: Plug.Conn.t()
  @type authorization_outcome :: {:authorized | :unauthorized, socket()}
  @type hook_outcome :: {:halt, socket()} | {:cont, socket()}
  @type condition ::
          boolean()
          | {atom(), any()}
          | (struct() -> boolean())
          | (Types.subject(), struct() -> boolean())
          | {(struct() -> boolean()),
             (struct() -> Ecto.Query.t())}
          | {(Types.subject(), struct() -> boolean()),
             (Types.subject(), struct()  -> Ecto.Query.t())}

  @typedoc """
  - `:authorization_module` -- (Required) The app's authorization module that uses `use Permit`.
  - `preload_resource_in` -- (Optional) The list of actions that resources will be preloaded and authorized in, in addition to :show, :delete, :edit and :update.
  - `repo` -- (Required, unless :loader_fn defined) The application's Repo. If a :loader_fn is not given, it's used for fetching records in singular resource functions (:show, :edit, :update, :delete and other defined as :preload_resource_in).
  - `loader_fn` -- (Required, unless :repo defined) The loader, 1-arity function, used to fetch records in singular resource functions (:show, :edit, :update, :delete and other defined as :preload_resource_in). It is convenient to use context getter functions as loaders.
  - `resource` -- (Required) The struct module defining the specific resource the controller is dealing with.
  - `id_param_name` -- (Required, if singular record actions are present) The parameter name used to look for IDs of resources, passed to the loader function or the repo.
  - `action_crud_mapping` -- (Optional) The mapping of controller actions not corresponding to standard Phoenix controller action names to :create, :read, :update or :delete - it directs the authorization framework to look for a specific CRUD rule for that given controller action. For instance: [view: :read, show: :read]
  - `fallback_path` -- (Optional) A string, or a function taking (conn, params) returning a string, denoting redirect path when unauthorized. Defaults to "/".
  - `error_msg` -- (Optional) An error message to put into the flash when unauthorizd. Defaults to "You do not have permission to perform this action."
  - `handle_unauthorized - (Optional) A function taking (conn, plug_opts), performing specific action when authorization is not successful. Defaults to redirecting to :fallback_path.
  """
  @type plug_opts :: [
          authorization_module: module() | function(),
          prefilter: loader() | function(),
          resource_module: resource_module() | function(),
          preload_resource_in: list(atom()) | function(),
          id_param_name: id_param_name() | function(),
          action_crud_mapping: keyword(crud()) | function(),
          except: list(atom()) | function(),
          fallback_path: (Plug.Conn.t(), map() | keyword() -> binary()) | binary() | function(),
          error_msg: binary() | function(),
          handle_unauthorized: function()
        ]
end
