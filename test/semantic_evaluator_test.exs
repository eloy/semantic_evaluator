defmodule SemanticEvaluatorTest do
  use ExUnit.Case
  doctest SemanticEvaluator

  test "validate simple conditions" do
    ctx = %{"foo" => true, "bar" => false, "wadus" => true, "text_a" => "aaa", "text_b" => "bbb"}

    assert SemanticEvaluator.eval!("foo == true", ctx) == true
    assert SemanticEvaluator.eval!("bar == false", ctx) == true
    assert SemanticEvaluator.eval!("unset == nil", ctx) == true

    assert SemanticEvaluator.eval!("!text_c", ctx) == true
    assert SemanticEvaluator.eval!("!text_a", ctx) == false
    assert SemanticEvaluator.eval!("!!text_a", ctx) == true

    assert SemanticEvaluator.eval!("foo == wadus", ctx) == true
    assert SemanticEvaluator.eval!("foo == bar", ctx) == false
    assert SemanticEvaluator.eval!("foo == bar || foo == wadus", ctx) == true
    assert SemanticEvaluator.eval!("foo == bar && foo == wadus", ctx) == false
    assert SemanticEvaluator.eval!("foo != bar && foo == wadus", ctx) == true

    assert SemanticEvaluator.eval!("text_a == \"aaa\"", ctx) == true
    assert SemanticEvaluator.eval!("text_a == \"bbb\"", ctx) == false
    assert SemanticEvaluator.eval!("text_a != text_b", ctx) == true
  end

  test "validate simple conditions with using atoms" do
    ctx = %{foo: true, bar: false}

    assert SemanticEvaluator.eval!(":foo", ctx) == true
    assert SemanticEvaluator.eval!(":bar", ctx) == false
    assert SemanticEvaluator.eval!(":foo || :bar", ctx) == true
  end

  test "validate deep maps" do
    ctx = %{"user_data" => %{"foo" => true, "bar" => false, "wadus" => %{"a" => "a", "b" => "b"}}}
    assert SemanticEvaluator.eval!("user_data.foo", ctx) == true
    assert SemanticEvaluator.eval!("user_data.bar", ctx) == false
    assert SemanticEvaluator.eval!("user_data.wadus.a == \"a\" && user_data.wadus.b == \"b\"", ctx) == true
  end

  test "validate deep maps with atoms" do
    ctx = %{user_data: %{foo: true, bar: false, wadus: %{a: "a", b: "b"}}}
    assert SemanticEvaluator.eval!("user_data.foo", ctx) == true
    assert SemanticEvaluator.eval!("user_data.bar", ctx) == false
    assert SemanticEvaluator.eval!("user_data.wadus.a == \"a\" && user_data.wadus.b == \"b\"", ctx) == true
  end

  test "validate length of arrays" do
    ctx = %{foo: [1, 2]}
    assert SemanticEvaluator.eval!("length(foo) > 1", ctx) == true
    assert SemanticEvaluator.eval!("length(foo) > 4", ctx) == false
  end
end
