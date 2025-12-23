defmodule AppStoreServerLibrary.Models.DeliveryStatus do
  @moduledoc """
  A value that indicates whether the app successfully delivered an In-App Purchase that works properly.

  https://developer.apple.com/documentation/appstoreserverapi/deliverystatus
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:delivered, "DELIVERED")
    value(:undelivered_quality_issue, "UNDELIVERED_QUALITY_ISSUE")
    value(:undelivered_wrong_item, "UNDELIVERED_WRONG_ITEM")
    value(:undelivered_server_outage, "UNDELIVERED_SERVER_OUTAGE")
    value(:undelivered_other, "UNDELIVERED_OTHER")
  end
end
