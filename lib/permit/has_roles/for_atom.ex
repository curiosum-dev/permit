defimpl Permit.HasRoles, for: Atom do
  def roles(atom),
    do: [atom]
end
