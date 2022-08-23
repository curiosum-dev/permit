defmodule Permit.Actions.PhoenixActions do
  @moduledoc """

  """
  use Permit.Actions

  @impl Permit.Actions
  def include_crud_mapping, do: true

  @impl Permit.Actions
  def mappings,
    do: %{
      new: [:create],
      index: [:read],
      show: [:read],
      edit: [:update]
    }
end
