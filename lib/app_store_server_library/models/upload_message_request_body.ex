defmodule AppStoreServerLibrary.Models.UploadMessageRequestBody do
  @moduledoc """
  The request body for uploading a message, which includes the message text and an optional image reference.

  https://developer.apple.com/documentation/retentionmessaging/uploadmessagerequestbody
  """

  alias AppStoreServerLibrary.Models.UploadMessageImage
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          header: String.t(),
          body: String.t(),
          image: UploadMessageImage.t() | nil
        }

  defstruct [:header, :body, :image]

  @doc """
  Creates a new UploadMessageRequestBody struct from a map or keyword list with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    with :ok <- Validator.require_strings(map, ["header", "body"]),
         :ok <- validate_header_length(Map.get(map, :header)),
         :ok <- validate_body_length(Map.get(map, :body)),
         {:ok, image} <- build_image(Map.get(map, :image)) do
      {:ok, struct(__MODULE__, Map.put(map, :image, image))}
    end
  end

  @doc """
  Converts the struct to a map for JSON encoding with camelCase keys.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = request) do
    base = %{
      "header" => request.header,
      "body" => request.body
    }

    if request.image do
      Map.put(base, "image", UploadMessageImage.to_json_map(request.image))
    else
      base
    end
  end

  @doc """
  Creates a struct from a map with camelCase keys.
  """
  @spec from_json_map(map()) :: t()
  def from_json_map(map) do
    map
    |> new()
    |> case do
      {:ok, struct} -> struct
      {:error, {_type, msg}} -> raise ArgumentError, msg
    end
  end

  defp validate_header_length(header) when is_binary(header) do
    if byte_size(header) <= 66 do
      :ok
    else
      {:error, {:verification_failure, "header must be at most 66 characters"}}
    end
  end

  defp validate_header_length(_),
    do: {:error, {:verification_failure, "Invalid string field: header"}}

  defp validate_body_length(body) when is_binary(body) do
    if byte_size(body) <= 144 do
      :ok
    else
      {:error, {:verification_failure, "body must be at most 144 characters"}}
    end
  end

  defp validate_body_length(_),
    do: {:error, {:verification_failure, "Invalid string field: body"}}

  defp build_image(nil), do: {:ok, nil}

  defp build_image(%{} = image_map) do
    case UploadMessageImage.new(image_map) do
      {:ok, image} -> {:ok, image}
      {:error, _} = err -> err
    end
  end

  defp build_image(_), do: {:error, {:verification_failure, "Invalid map field: image"}}
end
