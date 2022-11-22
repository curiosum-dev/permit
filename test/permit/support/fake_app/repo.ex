defmodule Permit.FakeApp.Repo do
  use Ecto.Repo,
    otp_app: :permit,
    adapter: Ecto.Adapters.Postgres
end
