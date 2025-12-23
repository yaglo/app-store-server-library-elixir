defmodule AppStoreServerLibrary.Models.ConsumptionRequestReason do
  @moduledoc """
  The customer-provided reason for a refund request.

  https://developer.apple.com/documentation/appstoreservernotifications/consumptionrequestreason
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:unintended_purchase, "UNINTENDED_PURCHASE")
    value(:fulfillment_issue, "FULFILLMENT_ISSUE")
    value(:unsatisfied_with_purchase, "UNSATISFIED_WITH_PURCHASE")
    value(:legal, "LEGAL")
    value(:other, "OTHER")
  end
end
