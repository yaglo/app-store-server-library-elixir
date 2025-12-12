defmodule AppStoreServerLibrary.Models.RealtimeRequestBody do
  @moduledoc """
  The request body the App Store server sends to your Get Retention Message endpoint.

  https://developer.apple.com/documentation/retentionmessaging/realtimerequestbody
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          signed_payload: String.t() | nil
        }

  defstruct [:signed_payload]

  @doc """
  Creates a new RealtimeRequestBody struct.

  - Pass a map with camelCase or snake_case keys to receive `{:ok, t()} | {:error, ...}` with validation.
  - Pass a string (or nil) to receive the struct directly.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    with :ok <- Validator.optional_fields(map, [{"signed_payload", :string}]) do
      {:ok, struct(__MODULE__, map)}
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
