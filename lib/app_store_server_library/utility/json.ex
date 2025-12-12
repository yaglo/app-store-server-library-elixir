defmodule AppStoreServerLibrary.Utility.JSON do
  @moduledoc """
  Utility functions for JSON key conversion between camelCase and snake_case.
  """

  require Logger
  alias AppStoreServerLibrary.Models.Environment

  @doc """
  Converts a camelCase string (or already-atom key) to a snake_case atom when known, otherwise returns the snake_case string.
  """
  @spec camel_to_snake_atom(String.t() | atom()) :: atom() | String.t()
  def camel_to_snake_atom(atom) when is_atom(atom), do: atom

  def camel_to_snake_atom(camel_str) when is_binary(camel_str) do
    snake = camel_to_snake(camel_str)

    try do
      String.to_existing_atom(snake)
    rescue
      ArgumentError ->
        Logger.debug(fn ->
          "AppStoreServerLibrary: ignoring unknown JSON field #{inspect(camel_str)} (snake #{inspect(snake)})"
        end)

        snake
    end
  end

  @doc """
  Converts a camelCase string to a snake_case string.

  ## Examples

      iex> AppStoreServerLibrary.Utility.JSON.camel_to_snake("bundleId")
      "bundle_id"

      iex> AppStoreServerLibrary.Utility.JSON.camel_to_snake("originalTransactionId")
      "original_transaction_id"

      iex> AppStoreServerLibrary.Utility.JSON.camel_to_snake("notificationUUID")
      "notification_uuid"
  """
  @spec camel_to_snake(String.t() | any()) :: String.t()
  def camel_to_snake(string) when is_binary(string) do
    string
    |> Macro.underscore()
    |> String.trim_leading("_")
  end

  def camel_to_snake(other), do: to_string(other)

  @doc """
  Converts a snake_case atom or string to a camelCase string.

  ## Examples

      iex> AppStoreServerLibrary.Utility.JSON.snake_to_camel(:bundle_id)
      "bundleId"

      iex> AppStoreServerLibrary.Utility.JSON.snake_to_camel("original_transaction_id")
      "originalTransactionId"
  """
  @spec snake_to_camel(atom() | String.t()) :: String.t()
  def snake_to_camel(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> snake_to_camel()
  end

  def snake_to_camel(string) when is_binary(string) do
    [first | rest] = String.split(string, "_")
    Enum.join([first | Enum.map(rest, &String.capitalize/1)])
  end

  @doc """
  Converts a map with camelCase string keys to snake_case atom keys.
  Recursively converts nested maps and lists.

  Special handling:
  - `:environment` and `:receipt_type` fields are converted to atoms via `Environment.from_string/1`

  ## Examples

      iex> AppStoreServerLibrary.Utility.JSON.keys_to_atoms(%{"bundleId" => "com.example"})
      %{bundle_id: "com.example"}
  """
  @spec keys_to_atoms(map()) :: map()
  def keys_to_atoms(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      key = camel_to_snake_atom(k)
      value = convert_value(key, v)
      {key, value}
    end)
    |> Map.new()
  end

  # Handle environment and receipt_type fields that need string-to-atom conversion
  defp convert_value(key, value) when key in [:environment, :receipt_type] and is_binary(value) do
    Environment.from_string(value)
  end

  defp convert_value(_key, value) when is_map(value), do: keys_to_atoms(value)

  defp convert_value(_key, value) when is_list(value),
    do: Enum.map(value, &convert_value(nil, &1))

  defp convert_value(_key, value), do: value

  @doc """
  Converts a map with snake_case atom keys to camelCase string keys.
  Only converts the top level, does not recurse.

  ## Examples

      iex> AppStoreServerLibrary.Utility.JSON.keys_to_camel(%{bundle_id: "com.example"})
      %{"bundleId" => "com.example"}
  """
  @spec keys_to_camel(map()) :: map()
  def keys_to_camel(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {snake_to_camel(k), v} end)
    |> Map.new()
  end
end
