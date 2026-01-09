defmodule AppStoreServerLibrary.Models.GetMessageListResponse do
  @moduledoc """
  Represents the response for getting a list of messages.
  """

  alias AppStoreServerLibrary.Models.GetMessageListResponseItem

  @doc false
  @spec __nested_fields__() :: %{atom() => {:list | :single, module()}}
  def __nested_fields__ do
    %{message_identifiers: {:list, GetMessageListResponseItem}}
  end

  @type t :: %__MODULE__{
          message_identifiers: [GetMessageListResponseItem.t()]
        }

  defstruct [:message_identifiers]
end
