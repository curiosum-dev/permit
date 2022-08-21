defmodule Permit.Actions.PhoenixActions do
  @moduledoc """

  """
  use Permit.Actions

  @impl Permit.Actions
  def mappings,
    do:
      Map.merge(super(), %{
        new: [:create],
        index: [:read],
        show: [:read],
        edit: [:update]
      })
end
