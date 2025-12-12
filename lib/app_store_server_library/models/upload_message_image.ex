defmodule AppStoreServerLibrary.Models.UploadMessageImage do
  @moduledoc """
  The definition of an image with its alternative text.

  https://developer.apple.com/documentation/retentionmessaging/uploadmessageimage
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          image_identifier: String.t(),
          alt_text: String.t()
        }

  defstruct [:image_identifier, :alt_text]

  @doc """
  Creates a new UploadMessageImage struct from a map or keyword list with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    with :ok <- Validator.require_strings(map, ["image_identifier", "alt_text"]),
         :ok <- validate_alt_text_length(Map.get(map, :alt_text)) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  @doc """
  Converts the struct to a map for JSON encoding with camelCase keys.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = image) do
    %{
      "imageIdentifier" => image.image_identifier,
      "altText" => image.alt_text
    }
  end

  defp validate_alt_text_length(alt_text) when is_binary(alt_text) do
    if byte_size(alt_text) <= 150 do
      :ok
    else
      {:error, {:verification_failure, "alt_text must be at most 150 characters"}}
    end
  end
end
