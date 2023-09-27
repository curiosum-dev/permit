defmodule Permit.ResolverBase do
  @moduledoc ~S"""
  Provides a basis for building _resolver modules_. A resolver is conceptually a module containing functions answering the following questions:

  * Given current **permission configuration**, is a **subject** authorized to perform a certain **action** on a given **resource**?
  * Given current **permission configuration**, a certain **subject**, an **action** and a **resource**, as well as an **execution context** (e.g. including controller parameters, loader functions, etc.), load a resource (e.g. by ID) and check whether the subject is authorized to perform the action on the resource.
  * Given current **permission configuration**, a certain **subject**, an **action** and a **resource**, as well as an **execution context**, load all resources on which the subject can perform the action.

  The `Permit.ResolverBase` module implements `authorized?/4`, `authorize_and_preload_one!/5` and `authorize_and_preload_all!/5` functions to check against the permissions and provide a uniform API for the outcome of the resolution.

  Creating a resolver (see `Permit.Ecto.Resolver` as an example) requires the developer to implement the `c:resolve/6` callback that fetches data to be authorized against.

  Replacing the standard resolver (`Permit.Resolver`) with a more specific one (e.g. `Permit.Ecto.Resolver` from the `permit_ecto` library) is done by the usage of a different resolver module (e.g. `Permit.Ecto.Resolver`) instead of `Permit.Resolver` in the `__using__/1` macro of the module which implements the `Permit` behaviour. The `resolver_module/0` function has to be overridden to point to the new resolver (see `Permit.Ecto` for sample usage).
  """
  alias Permit.Types

  @doc ~S"""
  Implement to define a resolver's behavior.

  The callback takes arguments in the following order:
  * `subject` typically takes the current user (or a record that `Permit.SubjectMapping` maps it to),
  * `authorization_module` takes the application's authorization configuration (i.e. the module that calls `use Permit` or `use Permit.Ecto`, or any other module with `Permit` behaviour),
  * `resource_module` takes the resource module - often, in Ecto applications, it's an Ecto schema,
  * `action_group` takes a name of an action, e.g. in Phoenix it's taken from a controller `conn` or a LiveView `socket`'s `live_action`
  * `meta` - depending on the resolver's needs, it will carry metadata such as loader functions, Ecto query processing functions, controller params, etc. - this generally is private to the integration library a developer is creating,
  * `arity` - it takes `:all` if plural resolution is to be performed (e.g. `:index`), and `:one` if singular resolution is performed (e.g. `:show`)

  The callback implementation should use the arguments, including authorization context and application-specific context (particularly in `:meta` key), to resolve and return a record or records according to the spec.

  Returned value:
  * `{:authorized, object}` in a singular action if a record is found and authorization is granted,
  * `{:authorized, [object]}` in a plural action if authorization to given action is granted - and it is assumed that the resolver filters out records that are not authorized,
  * `:not_found` in a singular action if no record found, and thus authorization cannot be checked _(note that in plural actions `{:authorized, []}` should be returned)
  * `:unauthorized` in a singular action if a record is found but authorization check is negative, or in a singular or plural action if the action itself is not authorized at all.
  """
  @callback resolve(
              Types.subject(),
              Types.authorization_module(),
              Types.resource_module(),
              Types.action_group(),
              Types.resolution_context(),
              :all | :one
            ) :: {:authorized, Types.object() | [Types.object()]} | :unauthorized | :not_found

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      @spec authorized?(
              Types.subject(),
              module(),
              Types.object_or_resource_module(),
              Types.action_group()
            ) :: boolean()

      def authorized?(subject, authorization_module, resource_or_module, action)
          when not is_nil(subject) do
        Permit.ResolverBase.authorized?(subject, authorization_module, resource_or_module, action)
      end

      @spec authorize_and_preload_one!(
              Types.subject(),
              module(),
              Types.resource_module(),
              Types.action_group(),
              map()
            ) :: {:authorized, [struct()]} | :unauthorized

      def authorize_and_preload_one!(subject, authorization_module, resource_module, action, meta)
          when not is_nil(subject) do
        resolve(subject, authorization_module, resource_module, action, meta, :one)
      end

      # Possible spec improvement:
      # originally term() was Ecto.Queryable.t(), figure out how to make it play with Ecto separated
      @spec authorize_and_preload_all!(
              Types.subject(),
              module(),
              Types.resource_module(),
              Types.action_group(),
              map()
            ) :: {:authorized, [struct()]} | :unauthorized | {:not_found, term()}

      def authorize_and_preload_all!(subject, authorization_module, resource_module, action, meta)
          when not is_nil(subject) do
        resolve(subject, authorization_module, resource_module, action, meta, :all)
      end
    end
  end

  @doc false
  def authorized?(subject, authorization_module, resource_or_module, action) do
    auth = authorization_module.can(subject)
    actions_module = authorization_module.actions_module()
    verify_fn = &Permit.verify_record(auth, resource_or_module, &1)

    Permit.Actions.verify_transitively!(actions_module, action, verify_fn)
  end
end
