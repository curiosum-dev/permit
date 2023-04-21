# Permit

Plain-Elixir, DSL-less, extensible authorization library for Elixir, also leveraging the power of Ecto, Phoenix and LiveView.

## Purpose and usage

Provide a single source of truth of action permissions throughout your codebase, making use of Ecto to have your Phoenix Controllers and LiveViews authorize access to resources without having to repeat yourself.

If you join the [monorepo bandwagon](https://blog.devgenius.io/embrace-the-mono-repo-3efcd09a38f8), you should be able to nicely drop your authorization into whatever's driven by Plug (Phoenix controllers) as well as into Phoenix LiveView, and perhaps even more - because it's very likely that your codebase will use multiple frameworks to process data that requires authorization.

### Configure & define your permissions
```elixir
defmodule MyApp.Authorization do
  use Permit, permissions_module: MyApp.Permissions, repo: MyApp.Repo
end

defmodule MyApp.Permissions do
  use Permit.RuleSyntax, actions_module: Permit.Actions.PhoenixActions
  
  def can(%{role: :admin} = user) do
    grant(user)
    |> all(MyApp.Blog.Article)
  end
  
  def can(%{id: user_id} = user) do
    grant(user)
    |> all(MyApp.Blog.Article, id: user_id)
    |> read(MyApp.Blog.Article) # allows :index and :show
  end
  
  def can(user), do: grant(user)
end
```

### Set up your controller

```elixir
defmodule MyAppWeb.Blog.ArticleController do
  use MyAppWeb, :controller
  
  use Permit.ControllerAuthorization,
    authorization_module: MyApp.Authorization,
    resource_module: MyApp.Blog.Article
    
  # assumption: current user is in assigns[:current_user] - this is configurable
    
  def show(conn, _params) do
    # At this point, the Article has already been preloaded by Ecto and checked for authorization
    # based on action name (:show).
    # It's available as the @loaded_resource assign.
    
    render(conn, "show.html")
  end
  
  def show(conn, _params) do
    # The list of Articles accessible by current user has been preloaded by Ecto
    # into the @loaded_resources assign.
  
    render(conn, "index.html")
  end
  
  # Optionally, implement the handle_unauthorized/1 callback to deal with authorization denial.
end
```

### Set up your LiveView
```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  live_session :authenticated, on_mount: Permit.AuthorizeHook do
    live("/articles", MyAppWeb.Blog.ArticlesLive, :index)
    live("/articles/:id", MyAppWeb.Blog.ArticlesLive, :show)
  end
end

defmodule MyAppWeb.Blog.ArticleLive do
  use Phoenix.LiveView
  
  use Permit.LiveViewAuthorization,
    authorization_module: MyAppWeb.Authorization,
    resource_module: MyApp.Blog.Article

  @impl true
  def user_from_session(session), do: # load current user
  
  # Both in the mount/3 callback and in a hook attached to the handle_params event,
  # authorization will be performed based on assigns[:live_action].
  
  # Optionally, implement the handle_unauthorized/1 callback to deal with authorization denial.
end
```

The library idea was originally briefed and announced in Michal Buszkiewicz's [Curiosum](https://curiosum.com) [Elixir Meetup #5 in 2022](https://youtu.be/AvUPX6cAjzk?t=3997).


## Roadmap

An outline of our development goals for both the "MVP" and further releases.

### Milestone 1

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
* [ ] Documentation
  - [ ] Examples of vanilla usage, Plug and Phoenix Framework integrations
  - [ ] Thorough documentation of the entire public API
* [ ] Dependency management
  - [ ] Introduce `permit_ecto` and `permit_phoenix` libraries providing the possibility of using the library without unneeded dependencies

### Further ideas

* [ ] Framework adapters
  - [x] Refactor resolver to provide a clear and straightforward way to develop library adapters
  - [ ] Research (and possibly PoC) of mapping or extending the paradigm to support Absinthe
  - [ ] Research on ideas of adapting to other frameworks
* [ ] New features and improvements
  - [ ] Explore possibilities to use compile time to improve performance (e.g. #23, #24)
  - [ ] Better support for DBMS other than Postgres (e.g. #10)
* [ ] Documentation
  - [ ] Improvement of private API documentation for library developers
  - [ ] Instructions and examples of integration with other frameworks

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `permit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:permit, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/permit>.

