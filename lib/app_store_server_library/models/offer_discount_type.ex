defmodule AppStoreServerLibrary.Models.OfferDiscountType do
  @moduledoc """
  The payment mode for a discount offer on an In-App Purchase.

  https://developer.apple.com/documentation/appstoreserverapi/offerdiscounttype
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:free_trial, "FREE_TRIAL")
    value(:pay_as_you_go, "PAY_AS_YOU_GO")
    value(:pay_up_front, "PAY_UP_FRONT")
    value(:one_time, "ONE_TIME")
  end
end
