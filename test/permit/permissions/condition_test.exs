defmodule Permit.Permissions.ConditionTest.Types do
  defmodule TestObject do
    @moduledoc false
    defstruct [:name, :key, :field_1, :field_2, :category]
  end

  defmodule Movie do
    @moduledoc false
    defstruct [:name, :category, :actors]
  end

  defmodule Category do
    @moduledoc false
    defstruct [:name, :type]
  end

  defmodule Type do
    @moduledoc false
    defstruct [:name, :description]
  end

  defmodule Description do
    @moduledoc false
    defstruct [:content]
  end

  defmodule Actor do
    @moduledoc false
    defstruct [:name, :age]
  end
end

defmodule Permit.Permissions.ConditionTest do
  use ExUnit.Case, async: true

  alias Permit.Permissions.ParsedCondition
  alias Permit.Permissions.ConditionParser

  alias Permit.Permissions.ConditionTest.Types.{
    TestObject,
    Category,
    Type,
    Description,
    Movie,
    Actor
  }

  describe "satisfied?/3" do
    test "should satisfy nested has-many associations" do
      condition = {:actors, {:==, [name: nil]}}

      test_object = %Movie{actors: [%Actor{name: nil}, %Actor{name: nil}]}

      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)

      condition = {:actors, {:==, [age: 123]}}

      test_object = %Movie{actors: [%Actor{age: 123}]}

      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)

      condition = {:actors, {:==, [age: 666]}}

      test_object = %Movie{actors: [%Actor{age: 666}, %Actor{age: 666}]}

      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)

      condition = {:actors, {:==, [age: 123, name: "test"]}}

      test_object = %Movie{
        actors: [%Actor{age: 123, name: "test"}, %Actor{age: 123, name: "test"}]
      }

      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)
    end

    test "should use ANY semantics for has-many associations" do
      # None of the actors have age 123, so should fail
      condition = {:actors, {:==, [age: 123]}}

      test_object = %Movie{actors: [%Actor{age: 666}]}

      refute ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)

      # With ANY semantics: at least one actor has age 666, so should PASS
      condition = {:actors, {:==, [age: 666]}}

      test_object = %Movie{actors: [%Actor{age: 123}, %Actor{age: 666}]}

      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)

      # At least one actor matches both age AND name conditions
      condition = {:actors, {:==, [age: 123, name: "test"]}}

      test_object = %Movie{
        actors: [%Actor{age: 123, name: "test"}, %Actor{age: 123, name: "test_666"}]
      }

      # With ANY semantics: first actor matches both conditions
      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)

      # No actor matches both conditions simultaneously
      condition = {:actors, {:==, [age: 123, name: "test"]}}

      test_object = %Movie{
        actors: [%Actor{age: 666, name: "test"}, %Actor{age: 123, name: "wrong"}]
      }

      # No single actor has both age 123 AND name "test"
      refute ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)
    end

    test "should not satisfy nested has-many associations when association is empty" do
      condition = {:actors, {:==, [age: 123]}}

      # An empty list of actors should NOT satisfy the condition
      # because there is no actor with age 123
      test_object = %Movie{actors: []}

      # Changed to any? semantic (PR #22 in permit_ecto)
      refute ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)
    end

    test "should satisfy nested association conditions" do
      condition = {
        :category,
        {:==, [name: "test_category", type: [name: "private"]]}
      }

      test_object = %Movie{
        category: %Category{name: "test_category", type: %Type{name: "private"}}
      }

      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)

      condition = {
        :category,
        {:==,
         [name: "test_category", type: [name: "private", description: [content: "test_content"]]]}
      }

      test_object = %Movie{
        category: %Category{
          name: "test_category",
          type: %Type{name: "private", description: %Description{content: "test_content"}}
        }
      }

      assert ConditionParser.build(condition)
             |> ParsedCondition.satisfied?(test_object, nil)
    end

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
