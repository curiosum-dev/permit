defmodule Permit.Actions.PhoenixActions do
  @moduledoc """

  """
  use Permit.Actions

  @impl Permit.Actions
  def grouping_schema do
    %{
      new: [:create],
      index: [:read],
      show: [:read],
      edit: [:update]
    }
    |> Map.merge(crud_grouping())
  end
end
