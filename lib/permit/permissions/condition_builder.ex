defmodule Permit.Permissions.ConditionBuilder do
  @callback build(Types.condition(), list()) :: ParsedCondition.t()
end
