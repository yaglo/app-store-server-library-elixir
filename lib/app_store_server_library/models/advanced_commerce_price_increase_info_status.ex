defmodule AppStoreServerLibrary.Models.AdvancedCommercePriceIncreaseInfoStatus do
  @moduledoc """
  The status of an Advanced Commerce price increase.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercepriceincreaseinfosstatus
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:scheduled, "SCHEDULED")
    value(:pending, "PENDING")
    value(:accepted, "ACCEPTED")
  end
end
