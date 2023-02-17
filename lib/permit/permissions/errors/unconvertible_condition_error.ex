defmodule Permit.Permissions.UnconvertibleConditionError do
  alias __MODULE__
  defexception [:message]

  @impl true
  def exception(errors) when is_list(errors) do
    msg = "Following conditions were not defined as convertible to Ecto.Query:\n"

    errors
    |> Enum.with_index(1)
    |> Enum.map(fn
      {{:condition_unconvertible, %{condition: condition, type: {:operator, operator}}}, i} ->
        "#{i}) Operator #{inspect(operator.symbol)} used in condition #{inspect(condition)} is not supported by Ecto.Query. Try different condition or construct your own query for it."

      {{:condition_unconvertible, %{condition: function, type: other}}, i}
      when other in [:function_1, :function_2] ->
        "#{i}) Functions like cannot be translated to Ecto.Query. Construct condition with operators or deliver yours query translation for the function #{Function.info(function, :name) |> elem(1)}."
    end)
    |> Enum.join("\n")
    |> then(&%UnconvertibleConditionError{message: msg <> &1})
  end
end
