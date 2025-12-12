defmodule AppStoreServerLibrary.API.APIException do
  @moduledoc """
  Exception raised when an App Store Server API request fails.

  Contains the HTTP status code, optional API error code, and error message.
  """

  alias AppStoreServerLibrary.API.APIError

  @type t :: %__MODULE__{
          http_status_code: integer(),
          api_error: atom() | nil,
          raw_api_error: integer() | nil,
          error_message: String.t() | nil
        }

  defexception [:http_status_code, :api_error, :raw_api_error, :error_message]

  @impl true
  def message(%__MODULE__{} = exception) do
    base =
      "App Store Server API error (HTTP #{exception.http_status_code})"

    case {exception.api_error, exception.error_message} do
      {nil, nil} -> base
      {nil, msg} -> "#{base}: #{msg}"
      {error, nil} -> "#{base}: #{error}"
      {error, msg} -> "#{base}: #{error} - #{msg}"
    end
  end

  @doc """
  Creates a new APIException.

  ## Parameters
  - http_status_code: The HTTP status code returned by the API
  - raw_api_error: The raw error code from the API response (optional)
  - error_message: The error message from the API response (optional)

  ## Examples

      iex> APIException.new(400, 4000006, "Invalid transaction identifier")
      %APIException{http_status_code: 400, api_error: :invalid_transaction_id, raw_api_error: 4000006, error_message: "Invalid transaction identifier"}

      iex> APIException.new(500)
      %APIException{http_status_code: 500, api_error: nil, raw_api_error: nil, error_message: nil}
  """
  @spec new(integer(), integer() | nil, String.t() | nil) :: t()
  def new(http_status_code, raw_api_error \\ nil, error_message \\ nil) do
    api_error =
      if raw_api_error do
        case APIError.to_atom(raw_api_error) do
          :unknown -> nil
          atom -> atom
        end
      else
        nil
      end

    %__MODULE__{
      http_status_code: http_status_code,
      api_error: api_error,
      raw_api_error: raw_api_error,
      error_message: error_message
    }
  end

  @doc """
  Checks if the error is retryable based on the API error code.
  """
  @spec retryable?(t()) :: boolean()
  def retryable?(%__MODULE__{raw_api_error: nil}), do: false

  def retryable?(%__MODULE__{raw_api_error: raw_api_error}),
    do: APIError.retryable?(raw_api_error)

  @doc """
  Returns the description of the API error if available.
  """
  @spec error_description(t()) :: String.t() | nil
  def error_description(%__MODULE__{raw_api_error: nil}), do: nil

  def error_description(%__MODULE__{raw_api_error: raw_api_error}),
    do: APIError.description(raw_api_error)

  @doc """
  Returns the Apple documentation URL for the error if available.
  """
  @spec doc_url(t()) :: String.t() | nil
  def doc_url(%__MODULE__{raw_api_error: nil}), do: nil
  def doc_url(%__MODULE__{raw_api_error: raw_api_error}), do: APIError.doc_url(raw_api_error)

  @doc """
  Creates an APIException from an error map returned by API calls.
  """
  @spec from_error_map(map()) :: t()
  def from_error_map(%{
        status_code: status_code,
        error_code: error_code,
        error_message: error_message
      }) do
    new(status_code, error_code, error_message)
  end

  def from_error_map(%{status_code: status_code, error_message: error_message}) do
    new(status_code, nil, error_message)
  end

  def from_error_map(%{status_code: status_code}) do
    new(status_code)
  end
end
