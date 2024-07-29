# Changelog
All notable changes to this project will be documented in this file.

* The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
* This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

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
