defmodule AppStoreServerLibrary.Models.RefundPreference do
  @moduledoc """
  A value that indicates your preferred outcome for the refund request.

  https://developer.apple.com/documentation/appstoreserverapi/refundpreference
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:decline, "DECLINE")
    value(:grant_full, "GRANT_FULL")
    value(:grant_prorated, "GRANT_PRORATED")
  end
end
