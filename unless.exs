defmodule ControlFlow do
  defmacro unless(expression, do: block) do
    quote do
      case unquote(expression) do
        x when x in [false, nil] ->
          unquote(block)
        _ ->
          unquote(nil)
      end
    end
  end
end
