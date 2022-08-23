defmodule Permit.Actions do
  @moduledoc """

  """
  alias __MODULE__
  alias Permit.Types

  @callback list_actions() :: [Types.controller_action()]
  @callback mappings() :: %{Types.controller_action() => [Types.crud()]}

  defmacro __using__(_opts) do
    quote do
      @behaviour Actions

      @impl Actions
      def mappings, do: %{
        create: [:create],
        read: [:read],
        update: [:update],
        delete: [:delete]
      }

      @impl Actions
      def list_actions,
        do: Map.keys(mappings())

      defoverridable mappings: 0, list_actions: 0
    end
  end

end
