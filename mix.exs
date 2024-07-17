defmodule Permit.MixProject do
  use Mix.Project

  @version "0.2.1"
  @source_url "https://github.com/curiosum-dev/permit/"

  def project do
    [
      app: :permit,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      consolidate_protocols: Mix.env() not in [:dev, :test],
      description: "Plain-Elixir, DSL-less, extensible authorization library for Elixir.",
      package: package(),
      dialyzer: [plt_add_apps: [:ex_unit]],
      docs: docs()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Michał Buszkiewicz", "Piotr Lisowski"],
      files: ["lib", "mix.exs", "README*"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications:
        case Mix.env() do
          :test -> [:logger]
          :dev -> [:logger]
          _ -> [:logger]
        end
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/permit/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "Permit",
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        Setup: [
          Permit,
          Permit.SubjectMapping
        ],
        Actions: [
          Permit.Actions,
          Permit.Actions.CrudActions,
          Permit.Actions.Forest,
          Permit.Actions.Traversal
        ],
        Permissions: [
          Permit.Permissions,
          Permit.Permissions.ActionFunctions,
          Permit.Permissions.DisjunctiveNormalForm,
          Permit.Permissions.ParsedCondition,
          Permit.Permissions.ParsedConditionList
        ],
        Operators: [
          Permit.Operators,
          Permit.Operators.GenOperator,
          Permit.Operators.Eq,
          Permit.Operators.Ge,
          Permit.Operators.Gt,
          Permit.Operators.Ilike,
          Permit.Operators.In,
          Permit.Operators.IsNil,
          Permit.Operators.Le,
          Permit.Operators.Like,
          Permit.Operators.Lt,
          Permit.Operators.Match,
          Permit.Operators.Neq
        ],
        Resolution: [
          Permit.Resolver,
          Permit.ResolverBase
        ],
        Types: [
          Permit.Types,
          Permit.Types.ConditionTypes
        ],
        Errors: [
          Permit.CycledDefinitionError,
          Permit.UndefinedActionError
        ]
      ]
    ]
  end
end
