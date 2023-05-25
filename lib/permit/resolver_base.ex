defmodule Permit.ResolverBase do
  alias Permit.Types

  @callback resolve(
              Types.subject(),
              module(),
              Types.resource_module(),
              Types.controller_action(),
              map(),
              :all | :one
            ) :: {:authorized, term() | list()} | :unauthorized | :not_found

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      @spec authorized?(
              Types.subject(),
              module(),
              Types.resource(),
              Types.controller_action()
            ) :: boolean()

      def authorized?(subject, authorization_module, resource_or_module, action)
          when not is_nil(subject) do
        auth = authorization_module.can(subject)
        actions_module = authorization_module.actions_module()
        verify_fn = &Permit.verify_record(auth, resource_or_module, &1)

        Permit.Actions.verify_transitively!(actions_module, action, verify_fn)
      end

      @spec authorize_and_preload_one!(
              Types.subject(),
              module(),
              Types.resource_module(),
              Types.controller_action(),
              map()
            ) :: {:authorized, [struct()]} | :unauthorized

      def authorize_and_preload_one!(subject, authorization_module, resource_module, action, meta)
          when not is_nil(subject) do
        resolve(subject, authorization_module, resource_module, action, meta, :one)
      end

      @spec authorize_and_preload_all!(
              Types.subject(),
              module(),
              Types.resource_module(),
              Types.controller_action(),
              map()
              # TODO: originally term() was Ecto.Queryable.t(), figure out how to make it play with Ecto separated
            ) :: {:authorized, [struct()]} | :unauthorized | {:not_found, term()}

      def authorize_and_preload_all!(subject, authorization_module, resource_module, action, meta)
          when not is_nil(subject) do
        resolve(subject, authorization_module, resource_module, action, meta, :all)
      end
    end
  end
end
