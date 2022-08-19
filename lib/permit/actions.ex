defmodule Permit.Actions do
  @moduledoc """

  """
  alias __MODULE__

  @callback list_actions() :: [atom()]
  @callback mappings() :: %{atom() => [atom()]}

  defmacro __using__(_opts) do
    quote do
      @behaviour Actions

      @impl Actions
      def mappings,
        do: %{
          create: [:create],
          read: [:read],
          update: [:update],
          delete: [:delete]
        }

      @impl Actions
      def list_actions,
        do: Map.keys(mappings())

      def map(action) do
        mappings()
        |> Map.get(action)
      end

      defoverridable mappings: 0, list_actions: 0
    end
  end
end
