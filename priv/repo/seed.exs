alias Permit.FakeApp.Item
alias Permit.FakeApp.Repo
alias Permit.FakeApp.User

{:ok, _pid} = Permit.FakeApp.Repo.start_link
Ecto.Adapters.SQL.Sandbox.mode(Permit.FakeApp.Repo, :manual)
 pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Repo)


Repo.insert(%User{id: 1, permission_level: 1})
Repo.insert(%User{id: 2})
Repo.insert(%User{id: 3})
Repo.insert(%Item{id: 1, owner_id: 1, permission_level: 1})
Repo.insert(%Item{id: 2, owner_id: 2, permission_level: 2, thread_name: "dmt"})
Repo.insert(%Item{id: 3, owner_id: 3, permission_level: 3})
