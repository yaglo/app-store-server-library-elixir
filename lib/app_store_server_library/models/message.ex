defmodule AppStoreServerLibrary.Models.Message do
  @moduledoc """
  A message identifier you provide in a real-time response to your Get Retention Message endpoint.

  https://developer.apple.com/documentation/retentionmessaging/message
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          message_identifier: String.t() | nil
        }

  defstruct [:message_identifier]

  @doc """
  Creates a new Message struct.

  Pass a map or keyword list with camelCase or snake_case keys to receive
  `{:ok, t()} | {:error, ...}` with validation.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    with :ok <- Validator.optional_fields(map, [{"message_identifier", :string}]) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  @doc """
  Converts the struct to a map for JSON encoding with camelCase keys.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = message) do
    if message.message_identifier do
      %{"messageIdentifier" => message.message_identifier}
    else
      %{}
    end
  end

  @doc """
  Creates a struct from a map with camelCase keys.
  """
  @spec from_json_map(map()) :: t()
  def from_json_map(map) do
    map
    |> JSON.keys_to_atoms()
    |> new()
    |> case do
      {:ok, struct} -> struct
      {:error, {_type, msg}} -> raise ArgumentError, msg
    end
  end
end
