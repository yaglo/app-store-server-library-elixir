defmodule AppStoreServerLibrary.Models.Enum do
  @moduledoc """
  Macros for defining enum-like modules with consistent patterns.

  Provides two macros:
  - `defenum/1` for string-based enums (e.g., "PURCHASED" -> :purchased)
  - `defenum_int/1` for integer-based enums (e.g., 1 -> :active)

  Both macros generate:
  - A `@type t` union of all atom values
  - `from_string/1` or `from_integer/1` with forward compatibility (unknown values pass through)
  - `to_string/1` or `to_integer/1` for converting atoms back

  ## Examples

      defmodule MyStringEnum do
        use AppStoreServerLibrary.Models.Enum

        defenum do
          value :pending, "PENDING"
          value :approved, "APPROVED"
          value :rejected, "REJECTED"
        end
      end

      MyStringEnum.from_string("PENDING")  #=> :pending
      MyStringEnum.from_string("UNKNOWN")  #=> "UNKNOWN"
      MyStringEnum.to_string(:pending)     #=> "PENDING"

      defmodule MyIntEnum do
        use AppStoreServerLibrary.Models.Enum

        defenum_int do
          value :off, 0
          value :on, 1
        end
      end

      MyIntEnum.from_integer(0)   #=> :off
      MyIntEnum.from_integer(99)  #=> 99
      MyIntEnum.to_integer(:off)  #=> 0
  """

  defmacro __using__(_opts) do
    quote do
      import AppStoreServerLibrary.Models.Enum, only: [defenum: 1, defenum_int: 1]
    end
  end

  @doc """
  Defines a string-based enum with forward compatibility.
  """
  defmacro defenum(do: block) do
    values = extract_values(block)

    type_union =
      values
      |> Enum.map(fn {atom, _string} -> atom end)
      |> Enum.reduce(fn atom, acc -> {:|, [], [atom, acc]} end)

    from_clauses =
      Enum.map(values, fn {atom, string} ->
        quote do
          def from_string(unquote(string)), do: unquote(atom)
        end
      end)

    to_clauses =
      Enum.map(values, fn {atom, string} ->
        quote do
          def to_string(unquote(atom)), do: unquote(string)
        end
      end)

    quote do
      @type t :: unquote(type_union)

      @doc """
      Convert string to atom.
      Returns the original string if the value is not recognized (forward compatibility).
      """
      @spec from_string(String.t()) :: t() | String.t()
      unquote_splicing(from_clauses)
      def from_string(unknown) when is_binary(unknown), do: unknown

      @doc """
      Convert atom to string.
      """
      @spec to_string(t()) :: String.t()
      unquote_splicing(to_clauses)
    end
  end

  @doc """
  Defines an integer-based enum with forward compatibility.
  """
  defmacro defenum_int(do: block) do
    values = extract_values(block)

    type_union =
      values
      |> Enum.map(fn {atom, _int} -> atom end)
      |> Enum.reduce(fn atom, acc -> {:|, [], [atom, acc]} end)

    from_clauses =
      Enum.map(values, fn {atom, int} ->
        quote do
          def from_integer(unquote(int)), do: unquote(atom)
        end
      end)

    to_clauses =
      Enum.map(values, fn {atom, int} ->
        quote do
          def to_integer(unquote(atom)), do: unquote(int)
        end
      end)

    quote do
      @type t :: unquote(type_union)

      @doc """
      Convert integer to atom.
      Returns the original integer if the value is not recognized (forward compatibility).
      """
      @spec from_integer(integer()) :: t() | integer()
      unquote_splicing(from_clauses)
      def from_integer(unknown) when is_integer(unknown), do: unknown

      @doc """
      Convert atom to integer.
      """
      @spec to_integer(t()) :: integer()
      unquote_splicing(to_clauses)
    end
  end

  # Extract {atom, value} pairs from the block
  defp extract_values({:__block__, _, statements}) do
    Enum.map(statements, &extract_value/1)
  end

  defp extract_values(single_statement) do
    [extract_value(single_statement)]
  end

  defp extract_value({:value, _, [atom, value]}) do
    {atom, value}
  end
end
