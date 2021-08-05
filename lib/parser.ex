defmodule Lox.Parser do
  @moduledoc """
  expression     → equality ;
  equality       → comparison ( ( "!=" | "==" ) comparison )* ;
  comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
  term           → factor ( ( "-" | "+" ) factor )* ;
  factor         → unary ( ( "/" | "*" ) unary )* ;
  unary          → ( "!" | "-" ) unary
                | primary ;
  primary        → NUMBER | STRING | "true" | "false" | "nil"
                | "(" expression ")" ;
  """

  alias Lox.Expr.{
    Binary,
    Grouping,
    Literal,
    Unary
  }

  def parse(tokens) do
    expression(tokens)
  end

  defp expression(tokens) do
    equality(tokens)
  end

  defp expression([]) do
    []
  end

  for token <- ~w(
    bang_equal
    equal_equal
  )a do
    # TODO: Do we need the line number on the struct?
    defp equality([left, {unquote(token), _line} = operator | rest]) do
      {right, rest} = comparison(rest)
      [%Binary{left: left, operator: operator, right: right} | expression(rest)]
    end
  end

  # FIXME: gotta pop one off the top
  defp equality(tokens) do
    expression(tokens)
  end

  # defp equality([expr | rest]) do
  #   [expr | equality(rest)]
  # end

  # defp equality([]) do
  #   []
  # end

  # Comparison

  defp comparison()

  # for token <- ~w(
  #   slash
  #   star
  # )a do
  #   defp factor()
  # end

  # Unary

  for token <- ~w(
    bang
    less
  )a do
    defp unary([{unquote(token), _line} | rest]) do
      {right, rest} = unary(rest)
      [%Unary{operator: unquote(token), right: right} | primary(rest)]
    end
  end

  defp unary(tokens) do
    primary(tokens)
  end

  # defp unary([]) do
  #   []
  # end

  # Primary
  for token <- ~w(
    true
    false
    nil
  )a do
    defp primary([{unquote(token), _line} | rest]) do
      [%Literal{value: unquote(token)} | primary(rest)]
    end
  end

  for type <- ~w(
    number
    string
  )a do
    defp primary([{{unquote(type), value}, _line} | rest]) do
      [%Literal{value: value} | primary(rest)]
    end
  end

  defp primary([{:left_paren, _line} | rest]) do
    {grouping, rest} = grouping(rest, [])
    [%Grouping{expression: grouping} | primary(rest)]
  end

  # defp primary([expr | rest]) do
  #   [expr | expression(rest)]
  # end

  # defp primary([]) do
  #   []
  # end

  defp primary(tokens) do
    expression(tokens)
  end

  # Grouping

  defp grouping([], _) do
    raise "FIXME: some kind of parsing error"
  end

  defp grouping([{:right_paren, _line} | rest], in_grouping) do
    {in_grouping
     |> Enum.reverse()
     |> expression(), rest}
  end

  defp grouping([token | rest], in_grouping) do
    grouping(rest, [token | in_grouping])
  end
end
