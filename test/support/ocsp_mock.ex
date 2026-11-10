defmodule AppStoreServerLibrary.TestOCSPMock do
  @moduledoc """
  Test OCSP checker that bypasses network calls.

  Configured as `:ocsp_checker`, it replaces the whole revocation check so the
  online verification path can run without contacting Apple's responders.
  """

  @spec check_ocsp_status(binary(), binary()) :: :ok
  def check_ocsp_status(_cert_der, _issuer_der), do: :ok

  @doc """
  Also configured as `:ocsp_requester`, so tests that call
  `ChainVerifier.check_ocsp_status/3` directly never reach the network.
  """
  @spec send_ocsp_request(String.t(), binary()) :: {:error, {atom(), String.t()}}
  def send_ocsp_request(_ocsp_url, _ocsp_request_der),
    do: {:error, {:retryable_verification_failure, "OCSP requests are disabled in tests"}}
end
