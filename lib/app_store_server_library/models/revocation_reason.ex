defmodule AppStoreServerLibrary.Models.RevocationReason do
  @moduledoc """
  The reason for a refunded transaction.

  https://developer.apple.com/documentation/appstoreserverapi/revocationreason
  """

  use AppStoreServerLibrary.Models.Enum

  defenum_int do
    value(:refunded_for_other_reason, 0)
    value(:refunded_due_to_issue, 1)
  end
end
