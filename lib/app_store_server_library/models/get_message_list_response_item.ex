defmodule AppStoreServerLibrary.Models.GetMessageListResponseItem do
  @moduledoc """
  Represents a message identifier and state information for a message.
  """

  alias AppStoreServerLibrary.Models.MessageState

  @type t() :: %__MODULE__{
          message_identifier: String.t() | nil,
          message_state: MessageState.t() | nil,
          raw_message_state: String.t() | nil
        }

  defstruct [
    :message_identifier,
    :message_state,
    :raw_message_state
  ]
end
