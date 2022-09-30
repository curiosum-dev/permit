defmodule Permit.Actions.UndefinedActionError do
  alias __MODULE__
  defexception [:message]

  @impl true
  def exception({action, module}) when is_atom(action) and is_atom(module) do
    msg =
      "Action #{inspect(action)} was not defined in module #{inspect(module)}. Please add this action to grouping_schema callback as a key."

    %UndefinedActionError{message: msg}
  end
end
