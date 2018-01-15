defmodule Assertion do

  # Extends this module via the `use` macro. When another module calls
  # `use Assertion`, this macro will be invoked.
  defmacro __using__(_options) do
    quote do
      # Imports the using module - not Assertion
      import unquote(__MODULE__)

      # Registers a tests attribute within the using module's context with
      # accumulate set to true. Almost like creating an instance variable.
      Module.register_attribute __MODULE__, :tests, accumulate: true

      # Registers the before_compile hook to invoke just before the using
      # module is finished compiling. Gives time for that module to accumulate
      # the @tests attribute.
      @before_compile unquote(__MODULE__)
    end
  end

  # Called when the @before_compile hook is invoked.
  defmacro __before_compile__(_env) do
    quote do
      # Proxies to our Assertion.Test.run/2 function. Generates less code in
      # the caller's context. That @tests attribute is from the
      # Module.register_attribute as listed above.
      def run, do: Assertion.Test.run(@tests, __MODULE__)
    end
  end

  # Accumulates tests and their function blocks. Defines a function for each
  # test within the context of the using module.
  defmacro test(description, do: test_block) do
    # Convert description of test to an atom for use as a valid function name
    test_func = String.to_atom(description)
    quote do
      # Accumulates the `test_func` reference and description in the @tests
      # module attribute.
      @tests {unquote(test_func), unquote(description)}

      # Defining a function whose name is the description converted to an atom.
      # Function body is the passed `test_block`.
      def unquote(test_func)(), do: unquote(test_block)
    end
  end

  defmacro assert({operator, _, [lhs, rhs]}) do
    quote bind_quoted: [operator: operator, lhs: lhs, rhs: rhs] do
      Assertion.Test.assert(operator, lhs, rhs)
    end
  end
end

defmodule Assertion.Test do
  def run(tests, module) do
    Enum.each tests, fn {test_func, description} ->
      case apply(module, test_func, []) do
        :ok             -> IO.write "."
        {:fail, reason} -> IO.puts """

          ===============================================
          FAILURE: #{description}
          ===============================================
          #{reason}
          """
      end
    end
  end

  def assert(:==, lhs, rhs) when lhs == rhs, do: :ok
  def assert(:==, lhs, rhs) do
    {
      :fail,
      """
      Expected:       #{lhs}
      to be equal to: #{rhs}
      """
    }
  end

  def assert(:>, lhs, rhs) when lhs > rhs, do: :ok
  def assert(:>, lhs, rhs) do
    {
      :fail,
      """
      Expected:           #{lhs}
      to be greater than: #{rhs}
      """
    }
  end
end

# Including here for simplicity. This would normally be defined elsewhere.
defmodule MathTest do
  use Assertion

  test "integers can be added and subtracted" do
    assert 2 + 3 == 5
    assert 5 - 5 == 10
  end

  test "integers can be multiplied and divided" do
    assert 5 * 5 == 25
    assert 10 / 2 == 5
  end
end
