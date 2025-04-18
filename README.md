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

If you join the [monorepo bandwagon](https://blog.devgenius.io/embrace-the-mono-repo-3efcd09a38f8), you should be able to nicely drop your authorization into whatever's driven by Plug (Phoenix controllers) as well as into Phoenix LiveView, and perhaps even more - because it's very likely that your codebase will use multiple frameworks to process data that requires authorization.

[![Hex version badge](https://img.shields.io/hexpm/v/permit.svg)](https://hex.pm/packages/permit)
[![Actions Status](https://github.com/curiosum-dev/permit/actions/workflows/elixir.yml/badge.svg)](https://github.com/curiosum-dev/permit/actions)
[![Code coverage badge](https://img.shields.io/codecov/c/github/curiosum-dev/permit/master.svg)](https://codecov.io/gh/curiosum-dev/permit/branch/master)
[![License badge](https://img.shields.io/hexpm/l/permit.svg)](https://github.com/curiosum-dev/permit/blob/master/LICENSE.md)

### Configure & define your permissions
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
    |> all(MyApp.Blog.Article, id: user_id)
    |> read(MyApp.Blog.Article) # allows :index and :show
  end

  def can(user), do: permit()
end
```

### Set up your controller

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

  live_session :authenticated, on_mount: Permit.Phoenix.LiveView.AuthorizeHook do
    live("/articles", MyAppWeb.Blog.ArticlesLive, :index)
    live("/articles/:id", MyAppWeb.Blog.ArticlesLive, :show)
  end
end

defmodule MyAppWeb.Blog.ArticleLive do
  use Phoenix.LiveView

  use Permit.Phoenix.LiveView,
    authorization_module: MyAppWeb.Authorization,
    resource_module: MyApp.Blog.Article

  @impl true
  def fetch_subject(session), do: # load current user

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
* [x] Documentation
  - [x] Examples of vanilla usage, Plug and Phoenix Framework integrations
  - [x] Thorough documentation of the entire public API
* [ ] Dependency management
  - [x] Introduce `permit_ecto` and `permit_phoenix` libraries providing the possibility of using the library without unneeded dependencies

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
    {:permit, "~> 0.2.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/permit>.

## Contact

[Curiosum](https://curiosum.com)
