defmodule Permit.FakeApp.Authorization do
  alias Permit.FakeApp.{Permissions, Repo}

  use Permit, permissions_module: Permissions, repo: Repo
end
