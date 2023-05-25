defmodule Permit.MixProject do
  use Mix.Project

  def project do
    [
      app: :permit,
      version: "0.0.3",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      consolidate_protocols: Mix.env() != :test,
      description:
        "Plain-Elixir, DSL-less, extensible, agent-agnostic authorization library for Elixir.",
      package: package()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/curiosum-dev/permit/"},
      maintainers: ["Michał Buszkiewicz", "Piotr Lisowski"],
      files: ["lib", "mix.exs", "README*"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications:
        case Mix.env() do
          :test -> [:logger, :plug, :phoenix_live_view]
          :dev -> [:logger, :plug, :phoenix_live_view]
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
      {:phoenix_live_view, "~> 0.16", optional: true},
      {:postgrex, "~> 0.15.13", only: :test},
      {:jason, "~> 1.3", only: [:dev, :test]},
      {:floki, ">= 0.30.0", only: :test},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
