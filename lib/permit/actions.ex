defmodule Permit.Actions do
  @moduledoc """

  """
  alias __MODULE__
  alias Permit.Types

  @callback grouping_schema() :: %{Types.controller_action() => [Types.action_group()]}

  defmacro __using__(_opts) do
    quote do
      @behaviour Actions

      def crud_grouping,
        do: %{
          create: [],
          read: [],
          update: [],
          delete: []
        }

      @impl Actions
      def grouping_schema,
        do: crud_grouping()

      def list_actions do
        grouping_schema()
        |> Map.keys()
      end

      def list_groups do
        grouping_schema()
        |> Map.values()
        |> List.flatten()
        |> Kernel.++(list_actions())
        |> Enum.uniq()
      end

      def groups_for(action) do
        grouping_schema()
        |> Map.get(action, [])
      end

      defoverridable grouping_schema: 0
    end
  end
end
