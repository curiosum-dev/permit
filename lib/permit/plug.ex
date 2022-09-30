defmodule Permit.Plug do
  @moduledoc """
  Authorization plug for the web application.

  It automatically infers what CRUD action is represented by the currently executed controller
  action, and delegates to Permit to determine whether the action is authorized based
  on current user's role.

  Current user is always fetched from `conn.assigns[:current_user]`, and their role is taken
  from the module specified in the app's `use Permit` directive. For instance if it's
  configured as follows:

  ```
  # Authorization configuration module
  defmodule MyApp.Authorization do
    use Permit,
      repo: Lvauth.Repo,
      permissions_module: MyApp.Authorization.Permissions
  end

  # Permissions module - just as an example
  defmodule MyApp.Authorization.Permissions do
    use Permit.Rules

    def can(%{role: :manager} = role) do
      # A :manager can do all CRUD actions on RouteTemplate, and can do :read on User
      # if the User has public: true OR the User has :overseer_id equal to current user's
      # id.
      grant(role)
      |> all(Lvauth.Planning.RouteTemplate)
      |> read(Lvauth.Accounts.User, public: true)
      |> read(LvMainFrame.Accounts.User,
              fn user, other_user -> other_user.overseer_id == user.id end)
    end
  end
  ```

  Then controller can be configured the following way:

  ```
  defmodule LvauthWeb.Planning.RouteTemplateController do
    plug Permit.Plug,
      authorization_module: MyApp.Authorization,
      loader_fn: fn id -> Lvauth.Repo.get(Customer, id) end,
      resource_module: Lvauth.Management.Customer,
      id_param_name: "id",
      except: [:example],
      user_from_conn: fn conn -> conn.assigns[:signed_in_user] end
      handle_unauthorized: fn conn -> redirect(conn, to: "/foo") end

    def show(conn, params) do
      # 1. If assigns[:current_user] is present, the "id" param will be used to call
      #    Repo.get(Customer, params["id"]).
      # 2. can(role) |> read?(record) will be called on the loaded record and each user role.
      # 3. If authorization succeeds, the record will be stored in assigns[:loaded_resources].
      # 4. If any of the steps described above fails, the pipeline will be halted.
    end

    def index(conn, params) do
      # 1. If assigns[:current_user] is present, can(role) |> read?(Customer) will be called on each role
      # 2. If authorization succeeds, nothing happens.
      # 3. If any of the steps described above fails, the pipeline will be halted.
    end

    def details(conn, params) do
      # Behaves identically to :show because in :action_crud_mapping it's defined as :read.
    end

    def clone(conn, params) do
      # 1. If assigns[:current_user] is present, the "id" param will be used to call
      #    Repo.get(Customer, params["id"]).
      # 2. can(role) |> update?(record) will be called on the loaded record (as configured in :action_crud_mapping) and each role of user
      # 3. If authorization succeeds, the record will be stored in assigns[:loaded_resources].
      # 4. If any of the steps described above fails, the pipeline will be halted.
    end
  end
  ```

  ##
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Permit.{Resolver, Types}

  @spec init(Types.plug_opts()) :: Types.plug_opts()
  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t(), Types.plug_opts()) :: Plug.Conn.t()
  def call(conn, opts) do
    opts =
      opts
      |> Enum.map(fn
        {opt_name, opt_function} when is_function(opt_function, 0) ->
          {opt_name, opt_function.()}

        {opt_name, opt_value} ->
          {opt_name, opt_value}
      end)

    controller_action = action_name(conn)

    if controller_action in opts[:except] do
      conn
    else
      resource_module = opts[:resource_module]

      subject = opts[:user_from_conn].(conn)
      authorize(conn, opts, controller_action, subject, resource_module)
    end
  end

  @spec authorize(
          Plug.Conn.t(),
          Types.plug_opts(),
          Types.controller_action(),
          Types.subject() | nil,
          Types.resource()
        ) ::
          Plug.Conn.t()
  defp authorize(conn, opts, _controller_action, nil, _resource) do
    opts[:handle_unauthorized].(conn)
  end

  defp authorize(conn, opts, controller_action, subject, resource_module) do
    if controller_action in opts[:preload_resource_in] do
      authorize_and_preload_resource(conn, opts, controller_action, subject, resource_module)
    else
      just_authorize(conn, opts, controller_action, subject, resource_module)
    end
  end

  @spec just_authorize(
          Plug.Conn.t(),
          Types.plug_opts(),
          Types.controller_action(),
          Types.subject() | nil,
          Types.resource_module()
        ) ::
          Plug.Conn.t()
  defp just_authorize(conn, opts, controller_action, subject, resource_module) do
    authorization_module = Keyword.fetch!(opts, :authorization_module)

    Resolver.authorized_without_preloading?(
      subject,
      authorization_module,
      resource_module,
      controller_action
    )
    |> case do
      true -> conn
      false -> opts[:handle_unauthorized].(conn)
    end
  end

  @spec authorize_and_preload_resource(
          Plug.Conn.t(),
          Types.plug_opts(),
          Types.controller_action(),
          Types.subject() | nil,
          Types.resource_module()
        ) ::
          Plug.Conn.t()
  defp authorize_and_preload_resource(conn, opts, controller_action, subject, resource_module) do
    authorization_module = Keyword.fetch!(opts, :authorization_module)

    prefilter = Keyword.fetch!(opts, :prefilter)
    actions_module = authorization_module.actions_module()
    singular? = controller_action in actions_module.singular_groups()
    load_key = if singular? do :loaded_resource else :loaded_resources end

    if singular? do
      & Resolver.authorize_with_singular_preloading!/5
    else
      & Resolver.authorize_with_preloading!/5
    end
    |> apply([
      subject,
      authorization_module,
      resource_module,
      controller_action,
      fn resource -> prefilter.(controller_action, resource, conn.params) end
    ])
    |> case do
      {:authorized, record} ->
        conn
        |> assign(load_key, record)

      :unauthorized ->
        opts[:handle_unauthorized].(conn)
    end
  end
end
