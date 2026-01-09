defmodule AppStoreServerLibrary.Models.GetImageListResponse do
  @moduledoc """
  Represents the response for getting a list of images.
  """

  alias AppStoreServerLibrary.Models.GetImageListResponseItem

  @doc false
  @spec __nested_fields__() :: %{atom() => {:list | :single, module()}}
  def __nested_fields__ do
    %{image_identifiers: {:list, GetImageListResponseItem}}
  end

  @type t :: %__MODULE__{
          image_identifiers: [AppStoreServerLibrary.Models.GetImageListResponseItem.t()]
        }

  defstruct [:image_identifiers]
end
