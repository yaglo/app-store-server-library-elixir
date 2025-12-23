defmodule AppStoreServerLibrary.Models.PurchasePlatform do
  @moduledoc """
  Values that represent Apple platforms.

  https://developer.apple.com/documentation/storekit/appstore/platform
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:ios, "iOS")
    value(:mac_os, "macOS")
    value(:tv_os, "tvOS")
    value(:vision_os, "visionOS")
  end
end
