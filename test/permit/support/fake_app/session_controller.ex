defmodule Permit.FakeApp.SessionController do
  @moduledoc false
  use Phoenix.Controller

  alias Permit.FakeApp.User

  def create(conn, params) do
    user =
      params
      |> Enum.map(&parse_param/1)
      |> Map.new()
      |> Map.put(:__struct__, User)

    assign(conn, :current_user, user)
  end

  defp parse_param({k, list}) when is_list(list),
    do: {String.to_atom(k), Enum.map(list, &original_or_atomized_key_map/1)}

  defp parse_param({k, map}) when is_map(map),
    do: {String.to_atom(k), shallow_atomize_keys(map)}

  defp parse_param({k, value}),
    do: {String.to_atom(k), value}

  defp shallow_atomize_keys(map) do
    map
    |> Enum.map(fn {kk, vv} ->
      {String.to_atom(kk), vv}
    end)
    |> Map.new()
  end

  defp original_or_atomized_key_map(%{} = item),
    do: shallow_atomize_keys(item)

  defp original_or_atomized_key_map(item),
    do: item
end
