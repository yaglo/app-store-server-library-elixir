defmodule AppStoreServerLibrary.Models.SendAttemptResult do
  @moduledoc """
  The success or error information the App Store server records when it attempts to send an App Store server notification to your server.

  https://developer.apple.com/documentation/appstoreserverapi/sendattemptresult
  """

  @type t() ::
          :success
          | :timed_out
          | :tls_issue
          | :circular_redirect
          | :no_response
          | :socket_issue
          | :unsupported_charset
          | :invalid_response
          | :premature_close
          | :unsuccessful_http_response_code
          | :other

  @doc """
  Convert string to atom
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_result}
  def from_string("SUCCESS"), do: {:ok, :success}
  def from_string("TIMED_OUT"), do: {:ok, :timed_out}
  def from_string("TLS_ISSUE"), do: {:ok, :tls_issue}
  def from_string("CIRCULAR_REDIRECT"), do: {:ok, :circular_redirect}
  def from_string("NO_RESPONSE"), do: {:ok, :no_response}
  def from_string("SOCKET_ISSUE"), do: {:ok, :socket_issue}
  def from_string("UNSUPPORTED_CHARSET"), do: {:ok, :unsupported_charset}
  def from_string("INVALID_RESPONSE"), do: {:ok, :invalid_response}
  def from_string("PREMATURE_CLOSE"), do: {:ok, :premature_close}
  def from_string("UNSUCCESSFUL_HTTP_RESPONSE_CODE"), do: {:ok, :unsuccessful_http_response_code}
  def from_string("OTHER"), do: {:ok, :other}
  def from_string(_), do: {:error, :invalid_result}

  @doc """
  Convert atom to string
  """
  @spec to_string(t()) :: String.t()
  def to_string(:success), do: "SUCCESS"
  def to_string(:timed_out), do: "TIMED_OUT"
  def to_string(:tls_issue), do: "TLS_ISSUE"
  def to_string(:circular_redirect), do: "CIRCULAR_REDIRECT"
  def to_string(:no_response), do: "NO_RESPONSE"
  def to_string(:socket_issue), do: "SOCKET_ISSUE"
  def to_string(:unsupported_charset), do: "UNSUPPORTED_CHARSET"
  def to_string(:invalid_response), do: "INVALID_RESPONSE"
  def to_string(:premature_close), do: "PREMATURE_CLOSE"
  def to_string(:unsuccessful_http_response_code), do: "UNSUCCESSFUL_HTTP_RESPONSE_CODE"
  def to_string(:other), do: "OTHER"
end
