# Changelog
All notable changes to this project will be documented in this file.

* The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
* This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

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
