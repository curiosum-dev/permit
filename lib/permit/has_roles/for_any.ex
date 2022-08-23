defimpl Permit.HasRoles, for: Any do
  def roles(any),
    do: [any]
end
