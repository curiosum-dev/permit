defmodule Permit.FakeApp.NoResultsError do
  defexception [:message]

  def exception(_opts) do
    msg = """
    expected at least one result but got none
    """

    %__MODULE__{message: msg}
  end
end
