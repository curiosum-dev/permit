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
      def mappings, do: %{
        create: [],
        read: [],
        update: [],
        delete: []
      }

      @impl Actions
      def list_actions,
        do: Map.keys(mappings())

      defoverridable mappings: 0, list_actions: 0
    end
  end

end
