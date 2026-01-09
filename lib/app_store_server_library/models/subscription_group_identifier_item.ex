defmodule AppStoreServerLibrary.Models.SubscriptionGroupIdentifierItem do
  @moduledoc """
  Information for auto-renewable subscriptions, including signed transaction information and signed renewal information, for one subscription group.

  https://developer.apple.com/documentation/appstoreserverapi/subscriptiongroupidentifieritem
  """

  alias AppStoreServerLibrary.Models.LastTransactionsItem

  @doc false
  @spec __nested_fields__() :: %{atom() => {:list | :single, module()}}
  def __nested_fields__ do
    %{last_transactions: {:list, LastTransactionsItem}}
  end

  @type t :: %__MODULE__{
          subscription_group_identifier: String.t() | nil,
          last_transactions: [LastTransactionsItem.t()] | nil
        }

  defstruct [
    :subscription_group_identifier,
    :last_transactions
  ]
end
