defmodule Permit.Permissions.ConditionHelperTest do
  use ExUnit.Case, async: true


  describe "like_pattern_to_regex/2" do
    import Permit.Permissions.Condition.ConditionHelper,
      only: [like_pattern_to_regex: 2]

    test "ignore case when needed" do
      assert like_pattern_to_regex("abc[dupa]", ignore_case: true) == ~r/^abc\[dupa\]$/i
      assert like_pattern_to_regex("abc[du-pa]", ignore_case: true) == ~r/^abc\[du\-pa\]$/i
      assert like_pattern_to_regex("^ab$c(dupa)", ignore_case: false) == ~r/^\^ab\$c\(dupa\)$/
      assert like_pattern_to_regex(".*", ignore_case: true) == ~r/^\.\*$/i
    end

    test "doubled escape character is replaced" do
      assert like_pattern_to_regex("ab!!c[dupa]", ignore_case: true, escape: "!") == ~r/^ab!c\[dupa\]$/i
      assert like_pattern_to_regex("!!abc[du-pa]!!", ignore_case: false, escape: "!") == ~r/^!abc\[du\-pa\]!$/
      assert like_pattern_to_regex("^a!!!!b$c(dupa)", escape: "!") == ~r/^\^a!!b\$c\(dupa\)$/
      assert like_pattern_to_regex("!!.!!*!!", escape: "!") == ~r/^!\.!\*!$/
    end

    test "escape character works with %" do
      assert like_pattern_to_regex("CHUJCHUJa!!p!%a", ignore_case: true, escape: "!") == ~r/^CHUJCHUJa!p%a$/i
      assert like_pattern_to_regex("!!!%%abc[du-pa]!!", ignore_case: false, escape: "!") == ~r/^!%.*abc\[du\-pa\]!$/
      assert like_pattern_to_regex("^a!!!%!!b$c(dupa)!%", escape: "!") == ~r/^\^a!%!b\$c\(dupa\)%$/
      assert like_pattern_to_regex("%!!.%!%!!*!!%", escape: "!") == ~r/^.*!\..*%!\*!.*$/
    end

    test "escape character works with _" do
      assert like_pattern_to_regex("__!_CHUJCHUJa!!p!%a", ignore_case: true, escape: "!") == ~r/^.._CHUJCHUJa!p%a$/i
      assert like_pattern_to_regex("!!!%!__%abc[du-pa]!!", ignore_case: false, escape: "!") == ~r/^!%_..*abc\[du\-pa\]!$/
      assert like_pattern_to_regex("^!!_a!!!%!!b$!%!_", escape: "!") == ~r/^\^!.a!%!b\$%_$/
      assert like_pattern_to_regex("%!%!_%_.%!%!!*!!%", escape: "!") == ~r/^.*%_.*.\..*%!\*!.*$/
    end
  end

  describe "like_pattern_to_regex/1" do
    import Permit.Permissions.Condition.ConditionHelper,
      only: [like_pattern_to_regex: 1]

    test "simple conversions" do
      assert like_pattern_to_regex("abc") == ~r/^abc$/
      assert like_pattern_to_regex("123 ab c") == ~r/^123\ ab\ c$/
    end

    test "escape special regex characters" do
      assert like_pattern_to_regex("abc[dupa]") == ~r/^abc\[dupa\]$/
      assert like_pattern_to_regex("abc[du-pa]") == ~r/^abc\[du\-pa\]$/
      assert like_pattern_to_regex("^ab$c(dupa)") == ~r/^\^ab\$c\(dupa\)$/
      assert like_pattern_to_regex(".*") == ~r/^\.\*$/
    end

    test "replace % with .*" do
      assert like_pattern_to_regex("abc[du%pa]") == ~r/^abc\[du.*pa\]$/
      assert like_pattern_to_regex("a%bc[du-pa%]") == ~r/^a.*bc\[du\-pa.*\]$/
      assert like_pattern_to_regex("%^ab$c(dupa)%") == ~r/^.*\^ab\$c\(dupa\).*$/
      assert like_pattern_to_regex(".*%") == ~r/^\.\*.*$/
    end

    test "replace _ with ." do
      assert like_pattern_to_regex("a_bc[du%pa]") == ~r/^a.bc\[du.*pa\]$/
      assert like_pattern_to_regex("_a%bc[du-_pa%]") == ~r/^.a.*bc\[du\-.pa.*\]$/
      assert like_pattern_to_regex("%^a__b$c(dupa)__%") == ~r/^.*\^a..b\$c\(dupa\)...*$/
      assert like_pattern_to_regex("___.*%") == ~r/^...\.\*.*$/
    end
  end
end
