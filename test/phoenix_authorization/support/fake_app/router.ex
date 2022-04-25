defmodule PhoenixAuthorization.FakeApp.Router do
  @moduledoc false
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
    resources("/items", PhoenixAuthorization.FakeApp.ItemControllerUsingRepo)

    get("/details/:id", PhoenixAuthorization.FakeApp.ItemControllerUsingRepo, :details)

    get(
      "/action_without_authorizing",
      PhoenixAuthorization.FakeApp.ItemControllerUsingRepo,
      :action_without_authorizing
    )
  end
end
