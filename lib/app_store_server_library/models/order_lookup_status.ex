defmodule AppStoreServerLibrary.Models.OrderLookupStatus do
  @moduledoc """
  A value that indicates whether the order ID in the request is valid for your app.

  https://developer.apple.com/documentation/appstoreserverapi/orderlookupstatus
  """

  use AppStoreServerLibrary.Models.Enum

  defenum_int do
    value(:valid, 0)
    value(:invalid, 1)
  end
end
