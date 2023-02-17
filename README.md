# Permit

Plain-Elixir, DSL-less, extensible, [agent-agnostic](#agent-agnostic-what-does-it-mean) authorization library for Elixir.

Originally briefed and announced in Michal Buszkiewicz's [Curiosum](https://curiosum.com) [Elixir Meetup #5 in 2022](https://youtu.be/AvUPX6cAjzk?t=3997).

## Checklist - outline of development goals

* Rule definition syntax
  - [x] Defining rules for **C**reate, **R**ead, **U**pdate and **D**elete actions
  - [x] Defining rules for arbitrarily named actions
- [x] Authorization resolution
  - [x] Authorizing a subject to perform a specific action on a resource type (i.e. struct module, Ecto schema)
  - [x] Authorizing a subject to perform a specific action on a specific resource (i.e. struct, loaded Ecto record)
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
* [ ] Absinthe integration
  - [ ] Figuring out mapping and/or extending the current permission definition paradigm to accomodate GraphQL usage
  - [ ] Implementing a PoC
* [ ] Framework adapters
  - [x] Refactor resolver to provide a clear and straightforward way to develop library adapters
  - [ ] Figure out what other frameworks we could adapt to using this library
* [ ] Documentation
  - [ ] Examples of usage for each compatible framework and scenario
  - [ ] Guide for developing library adapters

## Agent-agnostic: what does it mean?

`permit` is implemented with extensibility in mind, and the purpose of this is to ensure that for all concerns of the app that require authorization a single permission definition base should be used as the source of truth.

For example, if you join the [monorepo bandwagon](https://blog.devgenius.io/embrace-the-mono-repo-3efcd09a38f8), you should be able to nicely drop your authorization into whatever's driven by Plug (Phoenix controllers) as well as into Phoenix LiveView, and perhaps even more - because it's very likely that your codebase will use multiple frameworks to process data that requires authorization.

Hence, for want of a better word, I coined the _agent-agnostic_ term to describe the mindset behind this - no matter if the _agent_ is Plug, Phoenix LiveView, or in fact whatever else you might write an adapter for (you're invited!), you'll basically want to just do something like this (LiveView example):

```elixir
use Permit.LiveViewAuthorization,
  authorization_module: MyApp.Authorization,
  resource_module: SomeEctoSchema
```

I should've explained what an _agent_ is according to this definition. An _agent_ is a source from which one may reason about:
* _who_ is doing the action (the subject),
* _what_ they are doing (the action - read, create, update, delete, or something custom-named),
* _what_ is the action performed on (the object).

In Phoenix, for example, you usually have something like `:current_user` in your conn's assigns (the subject), a `:show` controller action easily maps to be a `:read` action, and the object can usually be taken from `params[:id]`.

Likewise - in LiveView, you surely have a way to determine who the current user is. The action name can be taken from `assigns[:live_action]`, and the object can also be found by ID. In this case, it's also important to be able to use `handle_params` to trigger authorization when appropriate.

You can imagine different frameworks coming into play like this. In these particular cases, `Permit.LiveViewAuthorization` and `Permit.ControllerAuthorization` determine _the who and the what_ and talk to `Permit.Resolver` which, once _the who and the what_ is known, determines whether the current permissions should allow the user to perform the action. And this is exactly what you should do to create any other adapter.

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

