defmodule AppStoreServerLibrary.Models.TransactionReason do
  @moduledoc """
  The cause of a purchase transaction, which indicates whether it's a customer's purchase or a renewal for an auto-renewable subscription that the system initiates.

  https://developer.apple.com/documentation/appstoreserverapi/transactionreason
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:purchase, "PURCHASE")
    value(:renewal, "RENEWAL")
  end
end
