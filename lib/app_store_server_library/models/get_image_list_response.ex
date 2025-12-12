defmodule AppStoreServerLibrary.Models.GetImageListResponse do
  @moduledoc """
  Represents the response for getting a list of images.
  """

  @type t :: %__MODULE__{
          image_identifiers: [AppStoreServerLibrary.Models.GetImageListResponseItem.t()]
        }

  defstruct [:image_identifiers]
end
