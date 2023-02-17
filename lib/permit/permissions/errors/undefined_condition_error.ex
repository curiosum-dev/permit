defmodule Permit.Permissions.UndefinedConditionError do
  alias __MODULE__
  defexception [:message]

  @impl true
  def exception({{action, module}, permissions})
      when is_atom(action) and is_atom(module) and is_map(permissions) do
    msg =
      "Conditions were not defined for action #{inspect(action)} and module #{inspect(module)}.\nCurrent conditions are defined for #{inspect(Map.keys(permissions))}"

    %UndefinedConditionError{message: msg}
  end

  def exception({action, module}) when is_atom(action) and is_atom(module) do
    msg =
      "Conditions were not defined for action #{inspect(action)} and module #{inspect(module)}"

    %UndefinedConditionError{message: msg}
  end
end
