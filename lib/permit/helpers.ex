defmodule Permit.Helpers do
  @moduledoc false

  alias Permit.Types

  @spec resource_module_from_resource(Types.object_or_resource_module()) ::
          Types.resource_module()
  def resource_module_from_resource(resource) when is_atom(resource),
    do: resource

  def resource_module_from_resource(resource) when is_struct(resource),
    do: resource.__struct__
end
