defmodule Mix.Tasks.Lox do
  @shortdoc "Interpret file or start an interpreter REPL"

  @moduledoc """
  Interpret a single file.

  ```
  mix lox path/to/file
  ```

  Start an interpreter REPL.
  Press CTRL + d to exit.

  ```
  mix lox
  ```
  """

  use Mix.Task

  alias Lox.{
    Interpreter,
    Scanner
  }

  def run([file]), do: run_file(file, %Interpreter{})
  def run([]), do: run_repl(%Interpreter{})
  def run(_), do: Mix.Task.run("help", ["lox"])

  defp run_repl(interpreter) do
    "> "
    |> IO.gets()
    |> case do
      :eof ->
        nil

      source ->
        source
        |> interpret(interpreter)
        |> run_repl()
    end
  end

  defp run_file(file, interpreter) do
    file
    |> File.read!()
    |> interpret(interpreter)
  end

  defp interpret(source, interpreter) do
    Scanner.scan(source)
    interpreter
  end

  defp report_error(line, where, message) do
    Mix.shell().error("[line #{line}] Error #{where}: #{message}")
  end

  defp exit_error(line, where, message) do
    report_error(line, where, message)
    System.stop(65)
  end
end
