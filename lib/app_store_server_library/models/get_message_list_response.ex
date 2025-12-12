defmodule AppStoreServerLibrary.Models.GetMessageListResponse do
  @moduledoc """
  Represents the response for getting a list of messages.
  """

  alias AppStoreServerLibrary.Models.GetMessageListResponseItem

  @type t :: %__MODULE__{
          message_identifiers: [GetMessageListResponseItem.t()]
        }

  defstruct [:message_identifiers]
end
