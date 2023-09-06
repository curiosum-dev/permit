defmodule Permit.Actions.CrudActions do
  @moduledoc """
  Extends the predefined `Permit.Actions` module and defines the following action mapping:

  | **Action** | **Required permission** |
  |------------|-------------------------|
  | `:create`  | itself                  |
  | `:read  `  | itself                  |
  | `:delete`  | itself                  |
  | `:update`  | itself                  |

  For more information on defining and mapping actions, see `Permit.Actions` documentation.
  """

  use Permit.Actions
end
