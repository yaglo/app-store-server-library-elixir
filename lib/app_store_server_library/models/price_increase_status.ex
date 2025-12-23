defmodule AppStoreServerLibrary.Models.PriceIncreaseStatus do
  @moduledoc """
  The status that indicates whether an auto-renewable subscription is subject to a price increase.

  https://developer.apple.com/documentation/appstoreserverapi/priceincreasestatus
  """

  use AppStoreServerLibrary.Models.Enum

  defenum_int do
    value(:customer_has_not_responded, 0)
    value(:customer_consented_or_was_notified_without_needing_consent, 1)
  end
end
