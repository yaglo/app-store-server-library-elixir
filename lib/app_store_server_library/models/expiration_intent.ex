defmodule AppStoreServerLibrary.Models.ExpirationIntent do
  @moduledoc """
  The reason an auto-renewable subscription expired.

  https://developer.apple.com/documentation/appstoreserverapi/expirationintent
  """

  use AppStoreServerLibrary.Models.Enum

  defenum_int do
    value(:customer_cancelled, 1)
    value(:billing_error, 2)
    value(:customer_did_not_consent_to_price_increase, 3)
    value(:product_not_available, 4)
    value(:other, 5)
  end
end
