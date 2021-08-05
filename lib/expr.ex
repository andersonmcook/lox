defmodule Lox.Expr do
  # interpret
  # resolve
  # analyze

  @type t ::
          Binary.t()
          | Grouping.t()
          | Literal.t()
          | Unary.t()

  # @callback parenthesize(t) :: String.t()

  # def f(%module{} = expr) do
  #   module.parenthesize(expr)
  # end

  defmodule Binary do
    @type t :: %__MODULE__{}
    defstruct ~w(left operator right)a
  end

  defmodule Grouping do
    @type t :: %__MODULE__{}
    defstruct ~w(expression)a
  end

  defmodule Literal do
    @type t :: %__MODULE__{}
    defstruct ~w(value)a
  end

  defmodule Unary do
    @type t :: %__MODULE__{}
    defstruct ~w(operator right)a
  end
end

# defprotocol Lox.Expr do
#   def parenthesize(expr)
# end

# defimpl Lox.Expr, for: Lox.Expr.Binary do
#   def parenthesize(binary) do
#     parenthesize(binary.left) <> "#{operator <> parenthesize(binary.right)
#   end
# end

# defimpl Lox.Expr, for: Lox.Expr.Grouping do
#   def parenthesize(grouping) do
#     parenthesize(binary.left) <> operator <> parenthesize(binary.right)
#   end
# end

# defimpl Lox.Expr, for: Lox.Expr.Binary do
#   def parenthesize(binary) do
#     parenthesize(binary.left) <> operator <> parenthesize(binary.right)
#   end
# end

# defimpl Lox.Expr, for: Lox.Expr.Binary do
#   def parenthesize(binary) do
#     parenthesize(binary.left) <> operator <> parenthesize(binary.right)
#   end
# end

# expression     → literal
#                | unary
#                | binary
#                | grouping ;

# literal        → NUMBER | STRING | "true" | "false" | "nil" ;
# grouping       → "(" expression ")" ;
# unary          → ( "-" | "!" ) expression ;
# binary         → expression operator expression ;
# operator       → "==" | "!=" | "<" | "<=" | ">" | ">="
#                | "+"  | "-"  | "*" | "/" ;
