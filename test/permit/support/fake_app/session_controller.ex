defmodule Permit.FakeApp.SessionController do
  @moduledoc false
  use Phoenix.Controller

  alias Permit.FakeApp.User

  def create(conn, params) do
    user =
      params
      |> Enum.map(fn {k, v} ->
        value =
          case v do
            val when is_list(v) ->
              Enum.map(val, &original_or_atomized_key_map/1)

            %{} ->
              shallow_atomize_keys(v)

            _ ->
              v
          end

        {String.to_atom(k), value}
      end)
      |> Map.new()
      |> Map.put(:__struct__, User)

    assign(conn, :current_user, user)
  end

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
