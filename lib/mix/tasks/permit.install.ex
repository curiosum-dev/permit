if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Permit.Install do
    @shortdoc "Installs Permit authorization into your project"

    @moduledoc """
    Installs Permit authorization into your project.

    ## Usage

        mix permit.install

    ## Options

    - `--phoenix` - Include Phoenix integration (Permit.Phoenix)
    - `--no-ecto` - Do not include Ecto integration (use only base Permit)
    - `--authorization-module` - Authorization module name (default: `<MyApp>.Authorization`)
    - `--permissions-module` - Permissions module name (default: `<MyApp>.Authorization.Permissions`)
    - `--actions-module` - Actions module name (default: `<MyApp>.Authorization.Actions`)
    - `--repo` - Ecto repo module name (auto-detected if not specified)
    - `--router` - Phoenix router module (auto-detected if not specified)
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :permit,
        schema: [
          phoenix: :boolean,
          no_ecto: :boolean,
          authorization_module: :string,
          permissions_module: :string,
          actions_module: :string,
          repo: :string,
          router: :string
        ],
        defaults: [
          phoenix: false,
          no_ecto: false
        ],
        composes: [
          "permit_ecto.install",
          "permit_phoenix.install"
        ]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = igniter.args.options
      app_module = Igniter.Project.Module.module_name_prefix(igniter)

      authorization_module = parse_module(options[:authorization_module], Module.concat(app_module, Authorization))
      permissions_module = parse_module(options[:permissions_module], Module.concat(authorization_module, Permissions))
      actions_module = parse_module(options[:actions_module], Module.concat(authorization_module, Actions))

      no_ecto? = Keyword.get(options, :no_ecto, false)
      phoenix? = Keyword.get(options, :phoenix, false)

      igniter =
        if no_ecto? do
          igniter
          |> create_base_authorization_module(authorization_module, permissions_module)
          |> create_base_permissions_module(permissions_module)
        else
          compose_args =
            ["--authorization-module", inspect(authorization_module),
             "--permissions-module", inspect(permissions_module)]
            |> maybe_add_option(options, :repo)
            |> maybe_add_option_value("--actions-module", phoenix? && inspect(actions_module))

          Igniter.compose_task(igniter, "permit_ecto.install", compose_args)
        end

      igniter =
        if phoenix? do
          compose_args =
            ["--authorization-module", inspect(authorization_module),
             "--actions-module", inspect(actions_module)]
            |> maybe_add_option(options, :router)

          Igniter.compose_task(igniter, "permit_phoenix.install", compose_args)
        else
          igniter
        end

      igniter
    end

    defp create_base_authorization_module(igniter, authorization_module, permissions_module) do
      Igniter.Project.Module.create_module(igniter, authorization_module, """
        use Permit, permissions_module: #{inspect(permissions_module)}
      """)
    end

    defp create_base_permissions_module(igniter, permissions_module) do
      Igniter.Project.Module.create_module(igniter, permissions_module, """
        use Permit.Permissions, actions_module: Permit.Actions.CrudActions

        def can(_user) do
          permit()
        end
      """)
    end

    defp parse_module(nil, default), do: default
    defp parse_module(string, _default) when is_binary(string) do
      string
      |> String.split(".")
      |> Module.concat()
    end

    defp maybe_add_option(args, options, key) do
      case Keyword.get(options, key) do
        nil -> args
        value -> args ++ ["--#{key}", value]
      end
    end

    defp maybe_add_option_value(args, _flag, false), do: args
    defp maybe_add_option_value(args, _flag, nil), do: args
    defp maybe_add_option_value(args, flag, value), do: args ++ [flag, value]
  end
else
  defmodule Mix.Tasks.Permit.Install do
    @shortdoc "Installs Permit authorization into your project"
    @moduledoc "Installs Permit authorization into your project. Requires the `igniter` package."

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The `permit.install` task requires the `igniter` package.

      Please add `{:igniter, "~> 0.5"}` to your dependencies and run `mix deps.get`.
      """)
    end
  end
end
