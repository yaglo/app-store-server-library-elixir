defmodule AppStoreServerLibrary.TestOCSPMock do
  @moduledoc """
  Test OCSP requester that bypasses network calls.

  Returning `{:ok, :skip_validation}` tells ChainVerifier to treat the OCSP check as successful
  without invoking OTP's OCSP validation.
  """

  @spec send_ocsp_request(String.t(), binary()) :: {:ok, :skip_validation}
  def send_ocsp_request(_ocsp_url, _ocsp_request_der), do: {:ok, :skip_validation}
end
