defmodule SemanticEvaluator.Parser do
  require Logger

  def parse(str, ctx) when is_binary(str)do
    case str |> Code.string_to_quoted do
      {:ok, terms} -> {:ok, _parse(terms, ctx)}
      {:error, _}  -> {:invalid_terms}
    end
  end

  # atomic terms
  defp _parse(:true, _ctx), do: true
  defp _parse(:false, _ctx), do: false
  defp _parse(:nil, _ctx), do: nil

  defp _parse(term, ctx) when is_atom(term) do
    cond do
      Map.has_key? ctx, term -> Map.get(ctx, term)
      Map.has_key? ctx, Atom.to_string(term) -> Map.get(ctx, Atom.to_string(term))
      true -> nil
    end
  end

  defp _parse(term, _ctx) when is_integer(term), do: term
  defp _parse(term, _ctx) when is_float(term), do: term
  defp _parse(term, _ctx) when is_binary(term), do: term

  defp _parse([], _ctx), do: []
  defp _parse([h|t], ctx), do: [_parse(h, ctx) | _parse(t, ctx)]

  defp _parse({a, b}, ctx), do: {_parse(a, ctx), _parse(b, ctx)}
  defp _parse({:"{}", _place, terms}, ctx) do
    terms
    |> Enum.map(fn(i) -> _parse(i, ctx) end)
    |> List.to_tuple
  end

  defp _parse({:"%{}", _place, terms}, ctx) do
    for {k, v} <- terms, into: %{}, do: {_parse(k, ctx), _parse(v, ctx)}
  end

  defp _parse({:!, _place, [term]}, ctx)  do
    value = _parse(term, ctx)
    !value
  end

  defp _parse({:==, _place, [term_a, term_b]}, ctx)  do
    _parse(term_a, ctx) == _parse(term_b, ctx)
  end

  defp _parse({:!=, _place, [term_a, term_b]}, ctx)  do
    _parse(term_a, ctx) != _parse(term_b, ctx)
  end

  defp _parse({:<, _place, [term_a, term_b]}, ctx)  do
    _parse(term_a, ctx) < _parse(term_b, ctx)
  end

  defp _parse({:<=, _place, [term_a, term_b]}, ctx)  do
    _parse(term_a, ctx) <= _parse(term_b, ctx)
  end

  defp _parse({:>, _place, [term_a, term_b]}, ctx)  do
    _parse(term_a, ctx) > _parse(term_b, ctx)
  end

  defp _parse({:>=, _place, [term_a, term_b]}, ctx)  do
    _parse(term_a, ctx) >= _parse(term_b, ctx)
  end

  defp _parse({:&&, _place, terms}, ctx) when is_list(terms)do
    Enum.map(terms, fn(i) -> _parse(i, ctx) end) |> Enum.all?
  end

  defp _parse({:||, _place, terms}, ctx) when is_list(terms)do
    Enum.map(terms, fn(i) -> _parse(i, ctx) end) |> Enum.any?
  end

  defp _parse({term, _place_a, nil}, ctx) when is_atom(term) do
    _parse(term, ctx)
  end


  # Deep maps
  defp _parse({{:., _terms, terms}, _, []}, ctx) when is_list(terms)do
    Enum.reduce terms, ctx, fn(term, ctx) ->
      _parse(term, ctx)
    end
  end

  defp _parse({:length, _place, [term]}, ctx) do
    value = _parse(term, ctx)
    length(value)
  end



  defp _parse({term_type, _place, terms}, ctx) when is_list(terms)do
    Logger.info("#{term_type} => #{inspect(terms)}")
    output = Enum.map(terms, fn(i) -> _parse(i, ctx) end)
    Logger.info(inspect(output))
    terms
  end


  defp _parse({_term_type, _place, terms}, _ctx) do
    Logger.info("FINAL #{inspect(terms)}")
    terms # to ignore functions and operators
  end
end
