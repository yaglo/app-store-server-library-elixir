defmodule AppStoreServerLibrary.Models.GetImageListResponseItem do
  @moduledoc """
  An image identifier and state information for an image.

  https://developer.apple.com/documentation/retentionmessaging/getimagelistresponseitem
  """

  alias AppStoreServerLibrary.Models.ImageState

  @type t :: %__MODULE__{
          image_identifier: String.t() | nil,
          image_state: ImageState.t() | nil,
          raw_image_state: String.t() | nil
        }

  defstruct [
    :image_identifier,
    :image_state,
    :raw_image_state
  ]
end
