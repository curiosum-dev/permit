defmodule Permit.PlugTest.RouterHelper do
  @moduledoc """
  Conveniences for testing controller-related utilities abstracting
  from the main web app.

  Copied as a simplified and stripped-down version of RouterHelper from Phoenix tests.
  """

  import Plug.Test

  defmacro __using__(_) do
    quote do
      use Plug.Test
      import Permit.PlugTest.RouterHelper
    end
  end

  def call(conn_or_router, verb, path, params \\ nil, script_name \\ [])

  def call(%Plug.Conn{} = conn, verb, path, params, script_name) do
    router = Phoenix.Controller.router_module(conn)

    conn
    |> Plug.Adapters.Test.Conn.conn(verb, path, params)
    |> Plug.Conn.fetch_query_params()
    |> Map.put(:script_name, script_name)
    |> router.call(router.init([]))
  end

  def call(router, verb, path, params, script_name) do
    verb
    |> conn(path, params)
    |> Plug.Conn.fetch_query_params()
    |> Map.put(:script_name, script_name)
    |> router.call(router.init([]))
  end
end
