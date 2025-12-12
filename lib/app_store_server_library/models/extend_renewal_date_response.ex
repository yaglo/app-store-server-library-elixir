defmodule AppStoreServerLibrary.Models.ExtendRenewalDateResponse do
  @moduledoc """
  A response that indicates whether an individual renewal-date extension succeeded, and related details.

  https://developer.apple.com/documentation/appstoreserverapi/extendrenewaldateresponse
  """

  @type t :: %__MODULE__{
          original_transaction_id: String.t() | nil,
          web_order_line_item_id: String.t() | nil,
          success: boolean() | nil,
          effective_date: integer() | nil
        }

  defstruct [
    :original_transaction_id,
    :web_order_line_item_id,
    :success,
    :effective_date
  ]
end
