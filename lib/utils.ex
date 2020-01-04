defmodule Utils do
  @doc """
  Generate a alphanumeric id based on the number of characters in min, max
  """
  def gen_key() do
    min = String.to_integer("10000000", 36)
    max = String.to_integer("ZZZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end
end
