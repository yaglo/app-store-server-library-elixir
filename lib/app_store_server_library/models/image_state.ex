defmodule AppStoreServerLibrary.Models.ImageState do
  @moduledoc """
  The approval state of an image.

  https://developer.apple.com/documentation/retentionmessaging/imagestate
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:pending, "PENDING")
    value(:approved, "APPROVED")
    value(:rejected, "REJECTED")
  end
end
