defmodule AppStoreServerLibrary.Models.AutoRenewStatus do
  @moduledoc """
  The renewal status for an auto-renewable subscription.

  https://developer.apple.com/documentation/appstoreserverapi/autorenewstatus
  """

  use AppStoreServerLibrary.Models.Enum

  defenum_int do
    value(:off, 0)
    value(:on, 1)
  end
end
