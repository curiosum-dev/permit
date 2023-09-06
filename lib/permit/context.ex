defmodule Permit.Context do
  @moduledoc false

  alias Permit.Types
  alias Permit.Permissions

  defstruct permissions: Permissions.new(), subject: nil

  @type t :: %Permit.Context{
          permissions: Permissions.t(),
          subject: Types.subject() | nil
        }
end
