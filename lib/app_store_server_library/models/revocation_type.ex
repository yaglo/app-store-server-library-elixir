defmodule AppStoreServerLibrary.Models.RevocationType do
  @moduledoc """
  The type of the refund or revocation that applies to the transaction.

  https://developer.apple.com/documentation/appstoreserverapi/revocationtype
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:refund_full, "REFUND_FULL")
    value(:refund_prorated, "REFUND_PRORATED")
    value(:family_revoke, "FAMILY_REVOKE")
  end
end
