defmodule Permit.Permissions.ConditionTest.Types do
  defmodule TestObject do
    @moduledoc false
    defstruct [:name, :key, :field_1, :field_2]
  end
end

defmodule Permit.Permissions.ConditionTest do
  use ExUnit.Case, async: true

  alias Permit.Permissions.ParsedCondition
  alias Permit.Permissions.ConditionParser
  alias Permit.Permissions.ConditionTest.Types.TestObject

  describe "satisfied?/3" do
    test "should satisfy const condition" do
      assert ConditionParser.build(true)
             |> ParsedCondition.satisfied?(nil, nil)
    end

    test "should not satisfy const condition" do
      refute ConditionParser.build(false)
             |> ParsedCondition.satisfied?(nil, nil)
    end

    test "should satisfy simple condition" do
      assert ConditionParser.build({:key, 666})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      assert ConditionParser.build({:key, nil})
             |> ParsedCondition.satisfied?(%TestObject{}, nil)
    end

    test "should support comparison operator conditions" do
      assert ConditionParser.build({:key, {:==, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      refute ConditionParser.build({:key, {:!=, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      assert ConditionParser.build({:key, {:>=, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      assert ConditionParser.build({:key, {:<=, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      assert ConditionParser.build({:key, {:>=, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 777}, nil)

      refute ConditionParser.build({:key, {:<=, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 777}, nil)

      assert ConditionParser.build({:key, {:>, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 777}, nil)

      refute ConditionParser.build({:key, {:>, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      refute ConditionParser.build({:key, {:<, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)
    end

    test "should support alternative operator conditions" do
      assert ConditionParser.build({:key, {:eq, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      refute ConditionParser.build({:key, {:neq, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      assert ConditionParser.build({:key, {:ge, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      assert ConditionParser.build({:key, {:le, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      assert ConditionParser.build({:key, {:ge, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 777}, nil)

      refute ConditionParser.build({:key, {:le, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 777}, nil)

      assert ConditionParser.build({:key, {:gt, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 777}, nil)

      refute ConditionParser.build({:key, {:gt, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)

      refute ConditionParser.build({:key, {:lt, 666}})
             |> ParsedCondition.satisfied?(%TestObject{key: 666}, nil)
    end

    test "should support string operator conditions" do
      assert ConditionParser.build({:name, {:=~, ~r/name_+\d/}})
             |> ParsedCondition.satisfied?(%TestObject{name: "name_666"}, nil)

      assert ConditionParser.build({:name, {:match, ~r/name_+\d/}})
             |> ParsedCondition.satisfied?(%TestObject{name: "name_666"}, nil)

      assert ConditionParser.build({:name, {:like, "%ame!____", escape: "!"}})
             |> ParsedCondition.satisfied?(%TestObject{name: "name_666"}, nil)

      assert ConditionParser.build({:name, {:ilike, "NAME!____", escape: "!"}})
             |> ParsedCondition.satisfied?(%TestObject{name: "name_666"}, nil)
    end
  end
end
