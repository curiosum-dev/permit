defmodule Permit.Permissions.ParsedCondition.LikePatternCompiler do
  @moduledoc """
     Like pattern compiler
  """
  @stack [{"%", ".*"}, {"_", "."}]

  @spec to_regex(String.t(), keyword()) :: Regex.t()
  def to_regex(pattern, ops \\ [ignore_case: false]) do
    caseless? = case_switch(Keyword.get(ops, :ignore_case))

    Keyword.get(ops, :escape, "")
    |> stack_of_replacements()
    |> create_replacements_composition()
    |> then(& &1.(pattern))
    |> anchors()
    |> Regex.compile!(caseless?)
  end

  defp stack_of_replacements(""),
    do: @stack

  defp stack_of_replacements(esc),
    do: @stack ++ [{esc <> "_", "_"}, {esc <> "%", "%"}, {esc <> esc, esc}]

  defp anchors(str),
    do: "^#{str}$"

  defp create_replacements_composition(stack) do
    stack
    |> Enum.reduce(&Regex.escape/1, fn {splitter, joiner}, k ->
      &split_at_and_join(&1, splitter, joiner, k)
    end)
  end

  defp split_at_and_join(what, split_with, join_with, continue) do
    what
    |> String.split(split_with)
    |> Enum.map(continue)
    |> Enum.join(join_with)
  end

  defp case_switch(true), do: "i"
  defp case_switch(_), do: ""
end
