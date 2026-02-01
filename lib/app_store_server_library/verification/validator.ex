defmodule AppStoreServerLibrary.Verification.Validator do
  @moduledoc """
  Lightweight validation helpers for decoded payload maps.

  All checks operate on stringified keys to support both atom and string maps.
  """

  @type error :: {:error, {:verification_failure, String.t()}}

  @spec require_strings(map(), [String.t()]) :: :ok | error()
  def require_strings(map, keys) do
    map = string_key_map(map)

    if Enum.all?(keys, fn key -> is_binary(Map.get(map, key)) end) do
      :ok
    else
      {:error, {:verification_failure, "Missing or invalid: #{Enum.join(keys, ", ")}"}}
    end
  end

  @spec require_integers(map(), [String.t()]) :: :ok | error()
  def require_integers(map, keys) do
    map = string_key_map(map)

    if Enum.all?(keys, fn key -> integerish?(Map.get(map, key)) end) do
      :ok
    else
      {:error, {:verification_failure, "Missing or invalid: #{Enum.join(keys, ", ")}"}}
    end
  end

  @spec optional_string_list(map(), String.t()) :: :ok | error()
  def optional_string_list(map, key) do
    map = string_key_map(map)
    value = Map.get(map, key)

    cond do
      is_nil(value) ->
        :ok

      is_list(value) and Enum.all?(value, &is_binary/1) ->
        :ok

      true ->
        {:error, {:verification_failure, "Invalid string list field: #{key}"}}
    end
  end

  @type field_type ::
          :string | :integer | :number | :boolean | :list | :atom | :atom_or_string | :map | :any

  @doc """
  Validates that optional fields match the expected type when present.
  """
  @spec optional_fields(map(), [{String.t() | atom(), field_type()}]) :: :ok | error()
  def optional_fields(map, fields) when is_list(fields) do
    map = string_key_map(map)

    Enum.reduce_while(fields, :ok, fn {key, type}, :ok ->
      key = to_string(key)
      value = Map.get(map, key)

      if is_nil(value) or valid_type?(value, type) do
        {:cont, :ok}
      else
        {:halt,
         {:error, {:verification_failure, "Invalid #{field_type_label(type)} field: #{key}"}}}
      end
    end)
  end

  defp valid_type?(_value, :any), do: true
  defp valid_type?(value, :string), do: is_binary(value)
  defp valid_type?(value, :integer), do: is_integer(value)
  defp valid_type?(value, :number), do: is_number(value)
  defp valid_type?(value, :boolean), do: is_boolean(value)
  defp valid_type?(value, :list), do: is_list(value)
  defp valid_type?(value, :atom), do: is_atom(value)
  defp valid_type?(value, :atom_or_string), do: is_atom(value) or is_binary(value)
  defp valid_type?(value, :map), do: is_map(value)
  defp valid_type?(_value, _type), do: false

  defp field_type_label(:any), do: "any"
  defp field_type_label(:atom_or_string), do: "atom or string"
  defp field_type_label(:integer), do: "integer"
  defp field_type_label(:boolean), do: "boolean"
  defp field_type_label(:number), do: "number"
  defp field_type_label(type) when is_atom(type), do: Atom.to_string(type)

  @doc """
  Validates that an optional field (or list of fields) has a value contained in the allowed set.
  Accepts atoms or strings. Unknown values return a verification_failure.
  """
  @spec optional_enum(map(), String.t() | atom(), [atom() | String.t()]) :: :ok | error()
  def optional_enum(map, key, allowed) do
    map = string_key_map(map)
    value = Map.get(map, to_string(key))

    cond do
      is_nil(value) ->
        :ok

      enum_member?(value, allowed) ->
        :ok

      true ->
        {:error, {:verification_failure, "Invalid enum field: #{key}"}}
    end
  end

  @doc """
  Validates that optional integer fields fall within allowed integer domain.
  """
  @spec optional_integer_domain(map(), String.t() | atom(), [integer()]) :: :ok | error()
  def optional_integer_domain(map, key, allowed_integers) do
    map = string_key_map(map)
    value = Map.get(map, to_string(key))

    cond do
      is_nil(value) ->
        :ok

      is_integer(value) and value in allowed_integers ->
        :ok

      true ->
        {:error, {:verification_failure, "Invalid integer enum field: #{key}"}}
    end
  end

  @doc """
  Validates an optional integer field is in the allowed range, converts it to an atom
  via `enum_module.from_integer/1`, and stores the original integer in `raw_<field>`.

  Returns `{:ok, updated_map}` on success (or when the field is nil/missing),
  or `{:error, ...}` on validation failure. Uses `Map.put_new` for the raw field
  so an explicitly provided value is not overwritten.
  """
  @spec optional_integer_enum(map(), String.t() | atom(), [integer()], module()) ::
          {:ok, map()} | error()
  def optional_integer_enum(map, key, allowed_integers, enum_module) do
    str_key = to_string(key)
    str_map = string_key_map(map)
    value = Map.get(str_map, str_key)

    cond do
      is_nil(value) ->
        {:ok, map}

      is_integer(value) and value in allowed_integers ->
        atom_key = String.to_existing_atom(str_key)

        if Map.has_key?(map, atom_key) do
          raw_atom_key = String.to_existing_atom("raw_#{str_key}")

          updated =
            map
            |> Map.put(atom_key, enum_module.from_integer(value))
            |> Map.put_new(raw_atom_key, value)

          {:ok, updated}
        else
          raw_str_key = "raw_#{str_key}"

          updated =
            map
            |> Map.put(str_key, enum_module.from_integer(value))
            |> Map.put_new(raw_str_key, value)

          {:ok, updated}
        end

      true ->
        {:error, {:verification_failure, "Invalid integer enum field: #{str_key}"}}
    end
  end

  @doc """
  Validates an optional string field is in the allowed set, converts it to an atom
  via `enum_module.from_string/1`, and stores the original string in `raw_<field>`.

  Returns `{:ok, updated_map}` on success (or when the field is nil/missing),
  or `{:error, ...}` on validation failure. Uses `Map.put_new` for the raw field
  so an explicitly provided value is not overwritten.
  """
  @spec optional_string_enum(map(), String.t() | atom(), [atom() | String.t()], module()) ::
          {:ok, map()} | error()
  def optional_string_enum(map, key, allowed, enum_module) do
    str_key = to_string(key)
    str_map = string_key_map(map)
    value = Map.get(str_map, str_key)

    cond do
      is_nil(value) ->
        {:ok, map}

      is_atom(value) ->
        # Already converted (e.g., by keys_to_atoms for environment/receipt_type)
        {:ok, map}

      is_binary(value) and enum_member?(value, allowed) ->
        atom_key = String.to_existing_atom(str_key)

        if Map.has_key?(map, atom_key) do
          raw_atom_key = String.to_existing_atom("raw_#{str_key}")

          updated =
            map
            |> Map.put(atom_key, enum_module.from_string(value))
            |> Map.put_new(raw_atom_key, value)

          {:ok, updated}
        else
          raw_str_key = "raw_#{str_key}"

          updated =
            map
            |> Map.put(str_key, enum_module.from_string(value))
            |> Map.put_new(raw_str_key, value)

          {:ok, updated}
        end

      true ->
        {:error, {:verification_failure, "Invalid enum field: #{str_key}"}}
    end
  end

  defp enum_member?(value, allowed) when is_atom(value), do: value in allowed
  defp enum_member?(value, allowed) when is_binary(value), do: value in allowed
  defp enum_member?(_value, _allowed), do: false

  defp string_key_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp integerish?(value) when is_integer(value), do: true

  defp integerish?(value) when is_binary(value) do
    case Integer.parse(value) do
      {_, ""} -> true
      _ -> false
    end
  end

  defp integerish?(_), do: false
end
