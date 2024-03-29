defmodule Permit.CycledDefinitionError do
  @moduledoc """
  Raised when action groupings defined in a `Permit.Actions` implementation result in a circular dependency.
  """

  alias __MODULE__
  defexception [:message]

  @impl true
  def exception({trace, module}) when is_list(trace) and is_atom(module) do
    msg =
      "grouping_schema in module #{inspect(module)} has circular definition. Please remove cycle #{inspect(trace)}"

    %CycledDefinitionError{message: msg}
  end
end
