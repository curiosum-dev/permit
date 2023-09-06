defimpl Permit.SubjectMapping, for: Any do
  def subjects(subject), do: [subject]
end
