defmodule Mix.Tasks.Permit.InstallTest do
  use ExUnit.Case

  import Igniter.Test

  describe "permit.install --no-ecto" do
    test "creates authorization and permissions modules" do
      test_project()
      |> Igniter.compose_task("permit.install", ["--no-ecto"])
      |> assert_creates("lib/test/authorization.ex")
      |> assert_creates("lib/test/authorization/permissions.ex")
    end

    test "generated authorization module uses Permit with correct permissions module" do
      igniter =
        test_project()
        |> Igniter.compose_task("permit.install", ["--no-ecto"])
        |> apply_igniter!()

      source = Rewrite.source!(igniter.rewrite, "lib/test/authorization.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "use Permit, permissions_module: Test.Authorization.Permissions"
    end

    test "generated permissions module uses Permit.Permissions with CrudActions" do
      igniter =
        test_project()
        |> Igniter.compose_task("permit.install", ["--no-ecto"])
        |> apply_igniter!()

      source = Rewrite.source!(igniter.rewrite, "lib/test/authorization/permissions.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "use Permit.Permissions, actions_module: Permit.Actions.CrudActions"
      assert content =~ "def can(_user) do"
      assert content =~ "permit()"
    end

    test "uses custom authorization module name" do
      test_project()
      |> Igniter.compose_task("permit.install", [
        "--no-ecto",
        "--authorization-module",
        "Test.Auth"
      ])
      |> assert_creates("lib/test/auth.ex")
    end

    test "uses custom permissions module name" do
      test_project()
      |> Igniter.compose_task("permit.install", [
        "--no-ecto",
        "--authorization-module",
        "Test.Auth",
        "--permissions-module",
        "Test.Auth.Perms"
      ])
      |> assert_creates("lib/test/auth.ex")
      |> assert_creates("lib/test/auth/perms.ex")
    end
  end

  describe "permit.install defaults (with ecto)" do
    test "runs without error when ecto task is unavailable" do
      # When permit_ecto.install task is not available (different package),
      # compose_task should handle it gracefully
      igniter =
        test_project()
        |> Igniter.compose_task("permit.install", [])

      # Should not raise - the task handles missing sub-tasks gracefully
      assert %Igniter{} = igniter
    end
  end
end
