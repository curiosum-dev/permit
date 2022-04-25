defmodule PhoenixAuthorization.FakeApp.RouterUsingLoader do
  use Phoenix.Router

  pipeline :browser do
    plug(Plug.Session,
      store: :cookie,
      key: "_example_key",
      signing_salt: "8ixXSdpw"
    )

    plug(:fetch_session)
    plug(:fetch_flash)
  end

  scope "/" do
    pipe_through(:browser)

    post("/sign_in", PhoenixAuthorization.FakeApp.SessionController, :create)
    resources("/items", PhoenixAuthorization.FakeApp.ItemControllerUsingLoader)
  end
end
