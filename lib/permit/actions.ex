defmodule Permit.Actions do
  @moduledoc """

  """
  alias __MODULE__
  alias Permit.Types

  @callback list_actions() :: [Types.controller_action()]
  @callback mappings() :: %{Types.controller_action() => [Types.crud()]}
  @callback include_crud_mapping() :: boolean()

  defmacro __using__(_opts) do
    quote do
      @behaviour Actions

      def crud_mapping, do: %{
        create: [:create],
        read: [:read],
        update: [:update],
        delete: [:delete]
      }

      @impl Actions
      def mappings,
        do: crud_mapping()

      @impl Actions
      def list_actions do
        case include_crud_mapping() do
          true -> crud_mapping()
          false -> %{}
        end
        |> Map.merge(mappings())
        |> Map.keys()
      end

      defoverridable mappings: 0, list_actions: 0
    end
  end

end
