defmodule PhoenixAuthorization.FakeApp.Authorization do
  alias PhoenixAuthorization.FakeApp.{Permissions, Repo}

  use PhoenixAuthorization, permissions_module: Permissions, repo: Repo
end
