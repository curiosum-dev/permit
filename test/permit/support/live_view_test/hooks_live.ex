defmodule Permit.LiveViewTest.HooksLive do
  use Phoenix.LiveView, namespace: Permit

  alias Permit.FakeApp.{Authorization, Item, User}

  use Permit.LiveViewAuthorization,
    authorization_module: Authorization,
    resource_module: Item

  @impl true
  def prefilter(_action, Item, %{"id" => id}) do
    id =
      if is_bitstring(id) do
        String.to_integer(id)
      else
        id
      end

    Permit.FakeApp.Item.Context.filter_by_id(Item, id)
  end

  @impl true
  def handle_unauthorized(socket), do: {:cont, assign(socket, :unauthorized, true)}

  @impl true
  def user_from_session(session) do
    case session["token"] do
      "valid_token" -> %User{id: 1, roles: session["roles"] || []}
      _ -> nil
    end
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <button id="navigate_show" phx-click="navigate" phx-value-url="/items/1">show</button>
    <button id="navigate_edit" phx-click="navigate" phx-value-url="/items/1/edit">edit</button>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, mounted: true)}
  end

  @impl true
  def handle_event("navigate", %{"url" => url}, socket) do
    {:noreply, push_patch(socket, to: url)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply,
     assign(
       socket,
       :loaded_resource_was_visible_in_handle_params,
       Map.has_key?(socket.assigns, :loaded_resources) or
         Map.has_key?(socket.assigns, :loaded_resource)
     )}
  end

  @impl true
  def handle_call({:run, func}, _, socket), do: func.(socket)

  @impl true
  def handle_info({:run, func}, socket), do: func.(socket)

  def run(lv, func) do
    GenServer.call(lv.pid, {:run, func})
  end
end
