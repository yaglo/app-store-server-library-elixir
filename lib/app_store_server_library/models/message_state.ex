defmodule AppStoreServerLibrary.Models.MessageState do
  @moduledoc """
  The approval state of the message.

  https://developer.apple.com/documentation/retentionmessaging/messagestate
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:pending, "PENDING")
    value(:approved, "APPROVED")
    value(:rejected, "REJECTED")
  end
end
