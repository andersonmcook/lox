defmodule Lox.Scanner do
  @moduledoc """
  Scans lexemes
  """
  defstruct errors: [],
            line: 1,
            tokens: []

  @typep single_character_token ::
           :left_paren
           | :right_paren
           | :left_brace
           | :right_brace
           | :comma
           | :dot
           | :minus
           | :plus
           | :semicolon
           | :slash
           | :star

  @typep one_or_more_character_token ::
           :bang
           | :bang_equal
           | :equal
           | :equal_equal
           | :greater
           | :greater_equal
           | :less
           | :less_equal

  @typep literal ::
           :identifier
           | {:string, String.t()}
           | {:number, number}

  @typep lox_keyword ::
           :and
           | :class
           | :else
           | false
           | :fun
           | :for
           | :if
           | nil
           | :or
           | :print
           | :return
           | :super
           | :this
           | true
           | :var
           | :while

  @typep token ::
           single_character_token
           | one_or_more_character_token
           | literal
           | lox_keyword

  @type t :: %__MODULE__{
          errors: [{String.t(), pos_integer}],
          line: pos_integer,
          tokens: [{token, pos_integer}]
        }

  defguardp is_digit(char) when char in ?0..?9
  defguardp is_alpha(char) when char in ?a..?z or char in ?A..?Z or char == ?_
  defguardp is_alphanumeric(char) when is_alpha(char) or is_digit(char)

  @doc """
  Scans a string to return tokens and errors.
  """
  @spec scan(String.t()) :: t
  def scan(source) do
    source
    |> String.to_charlist()
    |> tokenize(%__MODULE__{})
    |> reverse()
  end

  defp reverse(scanner) do
    %{
      scanner
      | errors: Enum.reverse(scanner.errors),
        tokens: Enum.reverse([{:eof, scanner.line + 1} | scanner.tokens])
    }
  end

  defp add_error(scanner, error), do: Map.update!(scanner, :errors, &[{error, scanner.line} | &1])
  defp add_token(scanner, token), do: Map.update!(scanner, :tokens, &[{token, scanner.line} | &1])
  defp increment_line(scanner), do: Map.update!(scanner, :line, &(&1 + 1))

  # Skip comments
  defp skip([], scanner), do: scanner
  defp skip([?\n | rest], scanner), do: tokenize(rest, increment_line(scanner))
  defp skip([_ | rest], scanner), do: skip(rest, scanner)

  # Done
  defp tokenize([], scanner), do: scanner

  # New line
  defp tokenize([?\n | rest], scanner), do: tokenize(rest, increment_line(scanner))

  # Comments
  defp tokenize([?/, ?/ | rest], scanner), do: skip(rest, scanner)

  # Two characters
  for {token, chars} <- [
        bang_equal: [?!, ?=],
        equal_equal: [?=, ?=],
        less_equal: [?<, ?=],
        greater_equal: [?>, ?=]
      ] do
    defp tokenize([unquote_splicing(chars) | rest], scanner) do
      tokenize(rest, add_token(scanner, unquote(token)))
    end
  end

  # Whitespace
  for char <- [
        ?\r,
        ?\s,
        ?\t
      ] do
    defp tokenize([unquote(char) | rest], scanner), do: tokenize(rest, scanner)
  end

  # TODO: some of these repeating would be invalid syntax?

  # Single characters
  for {token, char} <- [
        left_paren: ?(,
        right_parent: ?),
        left_brace: ?{,
        right_brace: ?},
        bang: ?!,
        comma: ?,,
        equal: ?=,
        greater: ?>,
        less: ?<,
        minus: ?-,
        plus: ?+,
        semicolon: ?;,
        slash: ?/,
        star: ?*
      ] do
    defp tokenize([unquote(char) | rest], scanner) do
      tokenize(rest, add_token(scanner, unquote(token)))
    end
  end

  # Dot
  defp tokenize([?., char | rest], scanner) when is_digit(char) do
    tokenize(rest, add_error(scanner, "Floats require a leading 0"))
  end

  defp tokenize([?. | rest], scanner) do
    tokenize(rest, add_token(scanner, :dot))
  end

  # Strings
  defp tokenize([?" | rest], scanner), do: tokenize_string(rest, [], scanner)

  # Numbers
  defp tokenize([char | rest], scanner) when is_digit(char) do
    tokenize_number(rest, [char], scanner)
  end

  # Identifiers
  defp tokenize([char | rest], scanner) when is_alpha(char) do
    tokenize_identifier(rest, [char], scanner)
  end

  # Unexpected characters
  defp tokenize([char | rest], scanner) do
    tokenize(rest, add_error(scanner, "Unexpected character: #{char}"))
  end

  # Keyword and Identifier tokenizer
  defp tokenize_identifier([char | rest], chars, scanner) when is_alphanumeric(char) do
    tokenize_identifier(rest, [char | chars], scanner)
  end

  defp tokenize_identifier(rest, chars, scanner) do
    token =
      chars
      |> Enum.reverse()
      |> to_keyword_or_identifier()

    tokenize(rest, add_token(scanner, token))
  end

  # Number tokenizer
  defp tokenize_number([?., char | rest], chars, scanner) when is_digit(char) do
    # Reverse order because we will reverse again at the end
    tokenize_number(rest, [char, ?. | chars], scanner)
  end

  defp tokenize_number([char | rest], chars, scanner) when is_digit(char) do
    tokenize_number(rest, [char | chars], scanner)
  end

  defp tokenize_number([?. | rest], _chars, scanner) do
    tokenize(rest, add_error(scanner, "Floats cannot end with a decimal point"))
  end

  defp tokenize_number(rest, chars, scanner) do
    list = Enum.reverse(chars)

    dot_count =
      Enum.reduce_while(list, 0, fn
        ?., 1 -> {:halt, 2}
        ?., acc -> {:cont, acc + 1}
        _, acc -> {:cont, acc}
      end)

    scanner =
      cond do
        dot_count == 0 -> add_token(scanner, {:number, List.to_integer(list) + 0.0})
        dot_count == 1 -> add_token(scanner, {:number, List.to_float(list)})
        dot_count > 1 -> add_error(scanner, "Multiple decimal points in float")
      end

    tokenize(rest, scanner)
  end

  # String tokenizer
  defp tokenize_string([], _, scanner) do
    add_error(scanner, "Unterminated string.")
  end

  defp tokenize_string([?" | rest], chars, scanner) do
    tokenize(rest, add_token(scanner, {:string, reverse_to_string(chars)}))
  end

  defp tokenize_string([char | rest], chars, scanner) do
    tokenize_string(rest, [char | chars], scanner)
  end

  defp reverse_to_string(chars) do
    chars
    |> Enum.reverse()
    |> List.to_string()
  end

  for keyword <- ~w(
    and
    class
    else
    false
    for
    fun
    if
    nil
    or
    print
    return
    super
    this
    true
    var
    while
  )a do
    chars = Atom.to_charlist(keyword)
    defp to_keyword_or_identifier(unquote(chars)), do: unquote(keyword)
  end

  defp to_keyword_or_identifier(identifier), do: {:identifier, List.to_string(identifier)}
end
