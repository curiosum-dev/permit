# Changelog
All notable changes to this project will be documented in this file.

* The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
* This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

## [v0.4.0] - 2026-04-28

### Added

- `plural_actions/0` callback on `Permit.Actions`, mirroring `singular_actions/0`. Defaults to `[]`. Used by `Permit.Phoenix.Actions` to exclude collection style actions (e.g. `:list`, `:search`, `:feed`) from router based promotion to singular (#61)
- Igniter installer task (`mix permit.install`) for zero-config project setup (#59)

### Fixed

- Documentation typos (#58)

## [v0.3.3]

### Fixed

- [Breaking] The behaviour of predicate functions has been changed to match the behaviour of Permit.Ecto in has-many associations (#53).
  
  With two disjunctive conditions on the same has-many association, the predicate function will now return `true` if at least one of the conditions is met - matching the behaviour of Permit.Ecto which builds a JOIN query and naturally returns the base record if _any_ associated record matches the query condition.

  Example:
  ```elixir
  # Permissions
  defmodule MyApp.Permissions do
    use Permit

    def can(user) do
      # User can read articles they are authorized to view
      user
      |> can(:read, %Article{authorized_viewers: [%{id: user.id}]})
    end
  end
  
  # Article has no authorized viewers
  can(user) |> read?(%Article{authorized_viewers: []})
  => false
  
  # All authorized viewer records match current user
  can(user) |> read?(%Article{authorized_viewers: [%{id: user.id}]})
  => true
  
  # Any authorized viewer record matches current user
  can(user) |> read?(%Article{authorized_viewers: [%{id: user.id}, %{id: 123}]})
  => true
  
  # No authorized viewer records match current user
  can(user) |> read?(%Article{authorized_viewers: [%{id: 123}]})
  => false
  ```

## [v0.3.2]

### Fixed
- [Breaking] Predicate functions now respect action grouping. For example, when `Permit.Actions.grouping_schema/0` includes `show: [:read]`,
calling `can(user) |> show?(item)` will now check if the `:read` permission is granted. Previously, it would only check for `:show` directly.
This was inconsistent with the behaviour of Permit.Phoenix and is now fixed for consistency.

## [v0.3.1]
### Fixed
- Loader function now receives as its argument the entire `resolution_context` map, not just `params`.

## [v0.3.0]
### Changed
- [Breaking] Change order of args in `Permit.verify_record/3` and add delegation as `do?/3` when doing `use Permit`.

  This way, permisisons to perform a dynamically computed action can be checked like this:
  ```elixir
  action = :read
  can(user) |> do?(action, %Item{id: 1})
  ```
  instead of the previously required, rather clumsy, and undocumented notation:

  ```elixir
  # Note: this is the previously used argument order; as of now, arguments 2 and 3 have been reversed.
  can(user) |> Permit.verify_record(%Item{id: 1}, action)
  ```
  If you happened to use `Permit.verify_record(3)`, the way to migrate is swapping arguments 2 and 3 in all calls, or - better still - migrating to the `do?/3` syntactic sugar.

### Fixed
- Update CI configuration and dependencies.

## [v0.2.1]
### Fixed
- Fix runtime and compile-time warnings (#38).

## [v0.2.0]
### Added
- Allow nesting association-based conditions (#36). For example, predicates such as `read(Item, user: [id: user_id])` can now be written.

### Fixed
- Fix invalid function name in `Permit.Permissions.DisjunctiveNormalForm` (`join` -> `concatenate`).

## [v0.1.3]
### Fixed
- Fix action traversal (#31) - ensure that when defining permissions `all` always takes precedence over individual action permission conditions .

## [v0.1.2]
### Fixed
- Fix semantics of LIKE and ILIKE operators when a field's value is `nil` (#29).

### Other
- Update CI configuration

## [v0.1.1]
### Fixed
- Refactor condition parsing routines to resolve Permit.Ecto issue (#28).

## [v0.1.0]
Initial release.
