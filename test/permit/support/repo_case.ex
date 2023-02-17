defmodule Permit.RepoCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Permit.FakeApp.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  end
end
