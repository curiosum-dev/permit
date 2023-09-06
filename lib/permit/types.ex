defmodule Permit.Types do
  @moduledoc ~S"""
  Includes type definitions used across the codebase of `Permit`, as well as its extensions.
  """

  # Module types

  @typedoc ~S"""
  Represents a resource module that the authorization will be checked for. Typically, it is a struct representing a model of a business level entity, e.g. `Article` (not `%Article{}`).
  """
  @type resource_module :: module()

  @typedoc """
  Represents the application's main authorization module - the one that calls `use Permit` or `use Permit.Ecto`.
  """
  @type authorization_module :: module()

  @typedoc """
  Represents a resolver module - the one that implements the `Permit.ResolverBase` behaviour, typically via `use Permit.ResolverBase`.
  """
  @type resolver_module :: module()

  # Struct types
  @typedoc """
  Typically represents a current user in a given context.
  """
  @type subject :: struct()

  @typedoc """
  A struct instance for a business level entity. Its type is the authorization module.
  """
  @type object :: struct()

  # Atom types

  @typedoc """
  An action for which authorization is verified.
  """
  @type action_group :: atom()

  @typedoc """
  A name of a struct's field - typically, in structs such as Ecto schemas, etc., it will be an atom.
  """
  @type struct_field :: atom()

  # Mixed types

  @typedoc """
  Represents extra data for the purpose of resolving and preloading records by resolvers (`t:resolver_module/0`). It can include loader functions, query builder functions, controller parameters, etc. - it depends on the specifics of a resolver and is not meant for public usage.
  """
  @type resolution_context :: %{
          optional(:action_group) => action_group(),
          optional(:resource_module) => resource_module(),
          optional(:subject) => subject(),
          optional(:params) => map(),
          optional(atom()) => any()
        }

  @typedoc ~S"""
  An object or a resource module can be used when asking for a specific permission.

  ## Example
      ```
      can?(%User{role: :admin})
      |> read?(Article)

      can?(%User{role: :admin})
      |> read?(%Article{id: 5})
      ```
  """
  @type object_or_resource_module :: object() | resource_module()

  @typedoc ~S"""
  A resource identifier, practically always being an integer or a string (e.g. a UUID).
  """
  @type id :: integer() | binary()

  @typedoc """
  A function used for preloading records by the resolver based on a resolution context.
  """
  @type loader :: (resolution_context() -> object() | nil)

  # Permissions-related types

  @typedoc """
  Encapsulates the permissions configuration for the application's business domain.
  """
  @type permissions :: Permit.Permissions.t()

  @typedoc """
  Will generate code delegating to functions that return `Permit.Permissions`.
  """
  @type permissions_code :: Macro.t()
end
