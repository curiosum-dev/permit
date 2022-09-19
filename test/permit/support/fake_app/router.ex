defmodule Permit.FakeApp.Router do
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

    post("/sign_in", Permit.FakeApp.SessionController, :create)
    resources("/items", Permit.FakeApp.ItemControllerUsingRepo)

    get("/details/:id", Permit.FakeApp.ItemControllerUsingRepo, :show)

    get(
      "/action_without_authorizing",
      Permit.FakeApp.ItemControllerUsingRepo,
      :action_without_authorizing
    )
  end
end
