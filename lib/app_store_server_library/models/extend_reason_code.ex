defmodule AppStoreServerLibrary.Models.ExtendReasonCode do
  @moduledoc """
  The code that represents the reason for the subscription-renewal-date extension.

  https://developer.apple.com/documentation/appstoreserverapi/extendreasoncode
  """

  use AppStoreServerLibrary.Models.Enum

  defenum_int do
    value(:undeclared, 0)
    value(:customer_satisfaction, 1)
    value(:other, 2)
    value(:service_issue_or_outage, 3)
  end
end
