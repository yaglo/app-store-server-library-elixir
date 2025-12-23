defmodule AppStoreServerLibrary.Models.OfferType do
  @moduledoc """
  The type of offer.

  https://developer.apple.com/documentation/appstoreserverapi/offertype
  """

  use AppStoreServerLibrary.Models.Enum

  defenum_int do
    value(:introductory_offer, 1)
    value(:promotional_offer, 2)
    value(:offer_code, 3)
    value(:win_back_offer, 4)
  end
end
