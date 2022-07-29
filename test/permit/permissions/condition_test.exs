defmodule Permit.Permissions.ConditionTest.Types do
  defmodule TestObject do
    @moduledoc false
    defstruct [:name, :key, :field_1, :field_2]
  end
end

defmodule Permit.Permissions.ConditionTest do
  use ExUnit.Case, async: true

  alias Permit.Permissions.Condition
  alias Permit.Permissions.ConditionTest.Types.TestObject

  describe "satisfied?/3" do
    test "should satisfy const condition" do
      assert Condition.new(true)
             |> Condition.satisfied?(nil, nil)
    end

    test "should not satisfy const condition" do
      refute Condition.new(false)
             |> Condition.satisfied?(nil, nil)
    end

    test "should satisfy simple condition" do
      assert Condition.new({:key, 666})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      assert Condition.new({:key, nil})
             |> Condition.satisfied?(%TestObject{}, nil)
    end

    test "should support comparison operator conditions" do
      assert Condition.new({:key, {:==, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      refute Condition.new({:key, {:!=, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      assert Condition.new({:key, {:>=, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      assert Condition.new({:key, {:<=, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      assert Condition.new({:key, {:>=, 666}})
             |> Condition.satisfied?(%TestObject{key: 777}, nil)

      refute Condition.new({:key, {:<=, 666}})
             |> Condition.satisfied?(%TestObject{key: 777}, nil)

      assert Condition.new({:key, {:>, 666}})
             |> Condition.satisfied?(%TestObject{key: 777}, nil)

      refute Condition.new({:key, {:>, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      refute Condition.new({:key, {:<, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)
    end

    test "should support alternative operator conditions" do
      assert Condition.new({:key, {:eq, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      refute Condition.new({:key, {:neq, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      assert Condition.new({:key, {:ge, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      assert Condition.new({:key, {:le, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      assert Condition.new({:key, {:ge, 666}})
             |> Condition.satisfied?(%TestObject{key: 777}, nil)

      refute Condition.new({:key, {:le, 666}})
             |> Condition.satisfied?(%TestObject{key: 777}, nil)

      assert Condition.new({:key, {:gt, 666}})
             |> Condition.satisfied?(%TestObject{key: 777}, nil)

      refute Condition.new({:key, {:gt, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)

      refute Condition.new({:key, {:lt, 666}})
             |> Condition.satisfied?(%TestObject{key: 666}, nil)
    end

    test "should support string operator conditions" do
      assert Condition.new({:name, {:=~, ~r/name_+\d/}})
             |> Condition.satisfied?(%TestObject{name: "name_666"}, nil)

      assert Condition.new({:name, {:match, ~r/name_+\d/}})
             |> Condition.satisfied?(%TestObject{name: "name_666"}, nil)

      assert Condition.new({:name, {:like, "%ame!____", escape: "!"}})
             |> Condition.satisfied?(%TestObject{name: "name_666"}, nil)

      assert Condition.new({:name, {:ilike, "NAME!____", escape: "!"}})
             |> Condition.satisfied?(%TestObject{name: "name_666"}, nil)
    end
  end
end
