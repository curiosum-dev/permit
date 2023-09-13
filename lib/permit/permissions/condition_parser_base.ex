defmodule Permit.Permissions.ConditionParserBase do
  @moduledoc false

  alias Permit.Types.ConditionTypes
  alias Permit.Permissions.ParsedCondition

  @doc false
  @callback build(ConditionTypes.condition(), list()) :: ParsedCondition.t()
end
