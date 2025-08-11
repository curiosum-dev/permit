<div align="center">
  <img src="https://github.com/user-attachments/assets/f0352656-397d-4d90-999a-d3adbae1095f">

  <h1>Permit</h1>
  <p><strong>Plain-Elixir, DSL-less, extensible authorization library for Elixir.

</strong></p>

  [![Contact Us](https://img.shields.io/badge/Contact%20Us-%23F36D2E?style=for-the-badge&logo=maildotru&logoColor=white&labelColor=F36D2E)](https://curiosum.com/contact)
  [![Visit Curiosum](https://img.shields.io/badge/Visit%20Curiosum-%236819E6?style=for-the-badge&logo=elixir&logoColor=white&labelColor=6819E6)](https://curiosum.com/services/elixir-software-development)
  [![License: MIT](https://img.shields.io/badge/License-MIT-1D0642?style=for-the-badge&logo=open-source-initiative&logoColor=white&labelColor=1D0642)]()
</div>


<br/>

## Purpose and usage

Provide a single source of truth of action permissions throughout your codebase, making use of Ecto to have your Phoenix Controllers and LiveViews authorize access to resources without having to repeat yourself.

Permit supports multiple integration points across the Elixir ecosystem:
- **Phoenix Controllers & LiveView** - with support for LiveView 1.0 and Streams
- **GraphQL APIs** - through Absinthe integration (experimental)
- **Custom integrations** - extensible architecture for other frameworks

[![Hex version badge](https://img.shields.io/hexpm/v/permit.svg)](https://hex.pm/packages/permit)
[![Actions Status](https://github.com/curiosum-dev/permit/actions/workflows/elixir.yml/badge.svg)](https://github.com/curiosum-dev/permit/actions)
[![Code coverage badge](https://img.shields.io/codecov/c/github/curiosum-dev/permit/master.svg)](https://codecov.io/gh/curiosum-dev/permit/branch/master)
[![License badge](https://img.shields.io/hexpm/l/permit.svg)](https://github.com/curiosum-dev/permit/blob/master/LICENSE.md)

### Configure & define your permissions
Required package: `:permit`.
```elixir
defmodule MyApp.Authorization do
  use Permit, permissions_module: MyApp.Permissions
end

defmodule MyApp.Permissions do
  use Permit.Permissions, actions_module: Permit.Phoenix.Actions

  def can(%{role: :admin} = user) do
    permit()
    |> all(MyApp.Blog.Article)
  end

  def can(%{id: user_id} = user) do
    permit()
    |> all(MyApp.Blog.Article, author_id: user_id)
    |> read(MyApp.Blog.Article) # allows :index and :show
  end

  def can(user), do: permit()
end
```

### Set up your controller

Requires `:permit_phoenix` package, and optionally `:permit_ecto` for sourcing authorization data from the DB.

```elixir
defmodule MyAppWeb.Blog.ArticleController do
  use MyAppWeb, :controller

  use Permit.Phoenix.Controller,
    authorization_module: MyApp.Authorization,
    resource_module: MyApp.Blog.Article

  # assumption: current user is in assigns[:current_user] - this is configurable

  def show(conn, _params) do
    # At this point, the Article has already been preloaded by Ecto and checked for authorization
    # based on action name (:show).
    # It's available as the @loaded_resource assign.

    render(conn, "show.html")
  end

  def index(conn, _params) do
    # The list of Articles accessible by current user has been preloaded by Ecto
    # into the @loaded_resources assign.

    render(conn, "index.html")
  end

  # Optionally, implement the handle_unauthorized/1 callback to deal with authorization denial.
end
```

### Set up your LiveView

Requires `:permit_phoenix`, and optionally `:permit_ecto`.

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  live_session :authenticated, on_mount: Permit.Phoenix.LiveView.AuthorizeHook do
    live("/articles", MyAppWeb.Blog.ArticlesLive, :index)
    live("/articles/:id", MyAppWeb.Blog.ArticlesLive, :show)
  end
end

defmodule MyAppWeb.Blog.ArticleLive do
  use Phoenix.LiveView

  use Permit.Phoenix.LiveView,
    authorization_module: MyApp.Authorization,
    resource_module: MyApp.Blog.Article,
    use_stream?: true  # Enable LiveView 1.0 Streams support

  @impl true
  def fetch_subject(session), do: # load current user

  # Both in the mount/3 callback and in a hook attached to the handle_params event,
  # authorization will be performed based on assigns[:live_action].
  # With streams enabled, :index actions will use streams instead of assigns.

  # Optionally, implement the handle_unauthorized/1 callback to deal with authorization denial.
end
```

### Set up your GraphQL API with Absinthe

Requires `:permit_absinthe`, whereas `:permit_ecto` is automatically retrieved to provide Dataloader support - see [Permit.Absinthe docs](https://hexdocs.pm/permit_absinthe/Permit.Absinthe.Middleware.DataloaderSetup.html).

```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema
  use Permit.Absinthe, authorization_module: MyApp.Authorization

  object :article do
    permit schema: MyApp.Blog.Article

    field :id, :id
    field :title, :string
    field :content, :string
    field :author_id, :id
  end

  query do
    field :article, :article do
      permit action: :read
      arg :id, non_null(:id)
      resolve &load_and_authorize/2  # Automatically loads and authorizes based on permissions
    end

    field :articles, list_of(:article) do
      permit action: :read
      resolve &load_and_authorize/2  # Returns only articles accessible by current user
    end
  end

  mutation do
    field :create_article, :article do
      permit action: :create
      arg :title, non_null(:string)
      arg :content, non_null(:string)

      # Use middleware for complex authorization scenarios
      middleware Permit.Absinthe.Middleware.LoadAndAuthorize

      resolve fn _, args, %{context: %{current_user: user}} ->
        MyApp.Blog.create_article(user, args)
      end
    end
  end
end
```

### Quick authorization checks

Requires `:permit` for the basic checks, and `:permit_ecto` for `accessible_by!/3`.

```elixir
# Check permissions directly
can(current_user) |> update?(article)

# Generate Ecto queries based on permissions
MyApp.Authorization.accessible_by!(current_user, :read, Article)

# Use the friendly API for multiple actions
can(current_user) |> do([:read, :update], article)
```

## Ecosystem

Permit is designed as a modular ecosystem with multiple packages:

| Package | Version | Description |
|---------|---------|-------------|
| **[permit](https://hex.pm/packages/permit)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit.svg)](https://hex.pm/packages/permit) | Core authorization library |
| **[permit_ecto](https://hex.pm/packages/permit_ecto)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit_ecto.svg)](https://hex.pm/packages/permit_ecto) | Ecto integration for database queries |
| **[permit_phoenix](https://hex.pm/packages/permit_phoenix)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit_phoenix.svg)](https://hex.pm/packages/permit_phoenix) | Phoenix Controllers & LiveView integration |
| **[permit_absinthe](https://github.com/curiosum-dev/permit_absinthe)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit_absinthe.svg)](https://hex.pm/packages/permit_absinthe) | GraphQL API authorization via Absinthe |

## Recent Updates

**Version 0.3.0** brings several major improvements:
- **Phoenix LiveView 1.0 support** with Streams for managing large collections
- **Router-based action inference** - automatically derive action names from Phoenix routes
- **Friendly `can(user) |> do(action, resource)` API** for more readable permission checks
- **Enhanced performance** and better error handling

See our recent blog posts for more details:
- [Updates to Permit and Permit.Phoenix, announcing Permit.Absinthe](https://curiosum.com/blog/permit-open-source-update)
- [Future of Permit authorization library](https://curiosum.com/blog/permit-future-authorization-library)

## Roadmap

An outline of our development goals for both the "MVP" and further releases.

### Milestone 1

The following features of Permit (along with its companion packages), originally intended as an initial backlog, has already been fulfilled:

* Rule definition syntax
  - [x] Defining rules for **C**reate, **R**ead, **U**pdate and **D**elete actions
  - [x] Defining rules for arbitrarily named actions
- [x] Authorization resolution
  - [x] Authorizing a subject to perform a specific action on a resource type (i.e. struct module, Ecto schema)
  - [x] Authorizing a subject to perform a specific action on a specific resource (i.e. struct, loaded Ecto record)
* [x] Ecto integration
  - [x] Loading and authorizing a record based on a set of params (e.g. ID) and subject
  - [x] Building Ecto queries scoping accessible records based on subject and resource type
* [x] Phoenix Framework integration
  - Authorizing singular resource actions (e.g. `show`, `update`)
    - [x] Plug / Controller
    - [x] LiveView
  - Preloading record (based on params) in singular resource actions and authorizing the specific record
    - [x] Plug/Controller
    - [x] LiveView
  - Authorizing non-singular resource actions (e.g. `index`)
    - [x] Plug/Controller
    - [x] LiveView
  - Preloading accessible records in non-singular resource actions (e.g. `index`)
    - [x] Plug/Controller
    - [x] LiveView
* [x] Documentation
  - [x] Examples of vanilla usage, Plug and Phoenix Framework integrations
  - [x] Thorough documentation of the entire public API
* [x] Dependency management
  - [x] Introduce `permit_ecto` and `permit_phoenix` libraries providing the possibility of using the library without unneeded dependencies

### Future plans

This list of planned items relates to the main Permit repository as well as to [Permit.Ecto](https://github.com/curiosum_dev/permit_ecto), [Permit.Phoenix](https://github.com/curiosum_dev/permit_phoenix), [Permit.Absinthe](https://github.com/curiosum_dev/permit_absinthe) and possible future offspring repositories related to the Permit project.

* [ ] **Performance & Optimization**
  - [ ] Compile-time optimizations and caching
  - [ ] Static code analysis for authorization rules
  - [ ] Policy playground & visualization tools
  - [ ] Code generators for common authorization patterns with Permit.Ecto
* [ ] **Extended Framework Support**
  - [ ] Ash framework integration
  - [ ] Commanded (CQRS/ES) integration
  - [x] Absinthe integration - in progress
  - [ ] Phoenix route-based authorization
* [ ] **Research Ideas**
  - [ ] Explore feasibility of entity field-level authorization
  - [ ] Research alignment of Permit with PostgreSQL RLS

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `permit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:permit, "~> 0.3.0"}
  ]
end
```

For additional integrations, add the relevant packages:

```elixir
def deps do
  [
    {:permit, "~> 0.3.0"},
    {:permit_ecto, "~> 0.2.4"},     # For Ecto integration
    {:permit_phoenix, "~> 0.3.0"},  # For Phoenix & LiveView
    {:permit_absinthe, "~> 0.1.0"}     # For GraphQL (Absinthe)
  ]
end
```

## Documentation

- **Core library**: [hexdocs.pm/permit](https://hexdocs.pm/permit)
- **Ecto integration**: [hexdocs.pm/permit_ecto](https://hexdocs.pm/permit_ecto)
- **Phoenix integration**: [hexdocs.pm/permit_phoenix](https://hexdocs.pm/permit_phoenix)
- **Absinthe integration**: [hexdocs.pm/permit_absinthe](https://hexdocs.pm/permit_phoenix)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development setup

Just clone the repository, install dependencies normally, develop and run tests. When running Credo and Dialyzer, please use `MIX_ENV=test` to ensure tests and support files are validated, too.
### Media

* [_A Framework for Unified Authorization in Elixir_](https://youtu.be/AvUPX6cAjzk?t=3997), M. Buszkiewicz, Curiosum Elixir Meetup #5, May 2022
* [_Permit - An Uniform Authorization Library for Elixir_](https://www.youtube.com/watch?v=qNl3fKpzQFY), M. Buszkiewicz, Curiosum Elixir Meetup #8, August 2022
* _Authorization & Access Control: Case Studies and Practical Solutions using Elixir_, ElixirConf EU, May 2025 - publicly available on YouTube soon
* [_Introducing Permit: An Authorization Library for Elixir_](https://curiosum.com/blog/introducing-permit-library-for-elixir), Curiosum, August 2022
* [_Authorize access to your Phoenix app with Permit_](https://curiosum.com/blog/authorize-access-to-your-phoenix-app-with-permit), Curiosum, October 2023
* [_Updates to Permit and Permit.Phoenix, announcing Permit.Absinthe_](https://curiosum.com/blog/permit-open-source-update), Curiosum, Jun 2025
* [_Future of Permit authorization library_](https://curiosum.com/blog/permit-future-authorization-library), Curiosum, Jun 2025

### Community

- **Slack channel**: [Elixir Slack / #permit](https://elixir-lang.slack.com/archives/C091Q5S0GDU)
- **Issues**: [GitHub Issues](https://github.com/curiosum-dev/permit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/curiosum-dev/permit/discussions)
- **Blog**: [Curiosum Blog](https://curiosum.com/blog?search=permit)

## Contact

* Library maintainer: [Michał Buszkiewicz](https://github.com/vincentvanbush)
* [**Curiosum**](https://curiosum.com) - Elixir development team behind Permit

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
