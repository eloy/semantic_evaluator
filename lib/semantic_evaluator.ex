defmodule SemanticEvaluator do
  @moduledoc """
  Documentation for `SemanticEvaluator`.
  """

  def eval(str, ctx) do
    SemanticEvaluator.Parser.parse(str, ctx)
  end


  def eval!(str, ctx) do
    {:ok, result} = SemanticEvaluator.Parser.parse(str, ctx)
    result
  end

end
