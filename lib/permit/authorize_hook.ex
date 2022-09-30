defmodule Permit.AuthorizeHook do
  @moduledoc """
  Hooks into the :mount and :handle_params lifecycles to authorize the current action.
  The current action is denoted by the :live_action assign (retrieved from the router),
  for example with the following route definition:

      live "/organizations", OrganizationLive.Index, :index

  the :live_action assign value will be :index.

  ## Configuration

  In the router, use the :on_mount option of live_session to configure it, passing a tuple.
  For convenience, you might return this tuple from a function that you might import into the router.

    live_session :some_session, on_mount: Permit.AuthorizeHook do
      live "/organizations", MyLive.Index, :index
      # ...
    end

  ## Usage

  Authorization is done on live view mount and in handle_params (where the URL, and
  hence assigns.live_action, may change).

  A live view module using the authorization mechanism should mix in the LiveViewAuthorization
  module:

      defmodule MyAppWeb.DocumentLive.Index
        use Permit.LiveViewAuthorization
      end

  which adds the LiveViewAuthorization behavior with the following callbacks to be implemented -
  for example:

      # The related schema
      def resource_module, do: Document

      # Loader function for a singular resource in appropriate actions (:show, etc.); usually a context
      # function. If not defined, Repo.get is used by default.
      def loader_fn, do: fn id -> get_organization!(id) end

  Depending on whether you use `use MyAppWeb, :live_view` or not to configure your LiveViews,
  it might be more convenient to provide configuration as options when you mix it in via `use`.
  For instance:

      # my_app_web.ex
      def live_view do
        use Permit.LiveViewAuthorization,
          authorization_module: Lvauth.Authorization,
          fallback_path: "/unauthorized"
      end

      # your live view module
      defmodule MyAppWeb.PageLive do
        use MyAppWeb, :live_view

        @impl true
        def resource_module, do: MyApp.Item

        # you might or might not want to override something here
        @impl true
        def fallback_path: "/foo"
      end

  In actions like :show, where a singular resource is to be authorized and preloaded, it is preloaded into
  the :loaded_resources assign. This way, you can implement your :handle_params event without caring
  about loading the record:

      @impl true
      def handle_params(_params, _, socket) do
        {:noreply,
        socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:organization, socket.assigns.loaded_resources)}
      end

  Optionally, a handle_unauthorized/2 optional callback can be implemented, returning {:cont, socket}
  or {:halt, socket}. The default implementation returns:

      {:halt, push_redirect(socket, to: socket.view.fallback_path())}

  """
  import Phoenix.LiveView

  alias Permit.Types

  @spec on_mount(term(), map(), map(), Types.socket()) :: Types.hook_outcome()
  def on_mount(_opt, params, session, socket) do
    socket
    |> attach_params_hook(params, session)
    |> authenticate_and_authorize!(session, params)
  end

  defp authenticate_and_authorize!(socket, session, params) do
    socket
    |> authenticate(session)
    |> authorize(params)
    |> respond()
  end

  @spec authenticate(Types.socket(), map()) :: Types.socket()
  defp authenticate(socket, session) do
    current_user = socket.view.user_from_session(session)
    assign(socket, :current_user, current_user)
  end

  @spec authorize(Types.socket(), map()) :: Types.authorization_outcome()
  defp authorize(socket, params) do
    %{assigns: %{live_action: live_action}} = socket

    if live_action in socket.view.preload_resource_in() do
      preload_and_authorize(socket, params)
    else
      just_authorize(socket)
    end
  end

  @spec just_authorize(Types.socket()) :: Types.authorization_outcome()
  defp just_authorize(socket) do
    authorization_module = socket.view.authorization_module()
    resource_module = socket.view.resource_module()
    subject = socket.assigns.current_user
    action = socket.assigns.live_action

    case Permit.Resolver.authorized_without_preloading?(
           subject,
           authorization_module,
           resource_module,
           action
         ) do
      true -> {:authorized, socket}
      false -> {:unauthorized, socket}
    end
  end

  @spec preload_and_authorize(Types.socket(), map()) ::
          Types.authorization_outcome()
  defp preload_and_authorize(socket, params) do
    authorization_module = socket.view.authorization_module()
    actions_module = authorization_module.actions_module()
    resource_module = socket.view.resource_module()
    prefilter = &socket.view.prefilter/3 # TODO prefilter is optional callback
    postfilter = &socket.view.postfilter/1 # TODO postfilter is optional callback
    subject = socket.assigns.current_user
    action = socket.assigns.live_action
    singular? = action in actions_module.singular_groups()

    load_key =
      if singular? do
        :loaded_resource
      else
        :loaded_resources
      end

    if singular? do
      &Permit.Resolver.authorize_with_singular_preloading!/6
    else
      &Permit.Resolver.authorize_with_preloading!/6
    end
    |> apply([
      subject,
      authorization_module,
      resource_module,
      action,
      fn resource -> prefilter.(action, resource, params) end,
      postfilter
    ])
    |> case do
      {:authorized, records} ->
        {:authorized, assign(socket, load_key, records)}

      :unauthorized ->
        {:unauthorized, socket}

      :not_found ->
        # TODO figure out what to do here
        raise "Not Found"
    end
  end

  @spec respond(Types.authorization_outcome()) :: Types.hook_outcome()
  defp respond(authorization_outcome)

  defp respond({:unauthorized, socket}) do
    socket.view.handle_unauthorized(socket)
  end

  defp respond({:authorized, socket}) do
    {:cont, socket}
  end

  defp attach_params_hook(socket, _mount_params, session) do
    socket
    |> attach_hook(:params_authorization, :handle_params, fn params, _uri, socket ->
      authenticate_and_authorize!(socket, session, params)
    end)
  end
end
