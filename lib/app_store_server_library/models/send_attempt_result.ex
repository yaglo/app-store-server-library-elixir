defmodule AppStoreServerLibrary.Models.SendAttemptResult do
  @moduledoc """
  The success or error information the App Store server records when it attempts to send an App Store server notification to your server.

  https://developer.apple.com/documentation/appstoreserverapi/sendattemptresult
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:success, "SUCCESS")
    value(:timed_out, "TIMED_OUT")
    value(:tls_issue, "TLS_ISSUE")
    value(:circular_redirect, "CIRCULAR_REDIRECT")
    value(:no_response, "NO_RESPONSE")
    value(:socket_issue, "SOCKET_ISSUE")
    value(:unsupported_charset, "UNSUPPORTED_CHARSET")
    value(:invalid_response, "INVALID_RESPONSE")
    value(:premature_close, "PREMATURE_CLOSE")
    value(:unsuccessful_http_response_code, "UNSUCCESSFUL_HTTP_RESPONSE_CODE")
    value(:other, "OTHER")
  end
end
