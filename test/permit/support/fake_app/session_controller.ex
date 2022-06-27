defmodule Permit.FakeApp.SessionController do
  @moduledoc false
  use Phoenix.Controller

  alias Permit.FakeApp.User

  def create(conn, params) do
    shallow_atomize_keys = fn map ->
      map
      |> Enum.map(fn {kk, vv} ->
        {String.to_atom(kk), vv}
      end)
      |> Map.new()
    end

    original_or_atomized_key_map = fn
      %{} = item ->
        shallow_atomize_keys.(item)

      item ->
        item
    end

    user =
      params
      |> Enum.map(fn {k, v} ->
        value =
          case v do
            val when is_list(v) ->
              Enum.map(val, original_or_atomized_key_map)

            %{} ->
              shallow_atomize_keys.(v)

            _ ->
              v
          end

        {String.to_atom(k), value}
      end)
      |> Map.new()
      |> Map.put(:__struct__, User)

    assign(conn, :current_user, user)
  end
end
