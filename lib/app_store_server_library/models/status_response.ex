defmodule AppStoreServerLibrary.Models.StatusResponse do
  @moduledoc """
  A response that contains status information for all of a customer's auto-renewable subscriptions in your app.

  https://developer.apple.com/documentation/appstoreserverapi/statusresponse
  """

  alias AppStoreServerLibrary.Models.{Environment, SubscriptionGroupIdentifierItem}

  @doc false
  @spec __nested_fields__() :: %{atom() => {:list | :single, module()}}
  def __nested_fields__ do
    %{data: {:list, SubscriptionGroupIdentifierItem}}
  end

  @type t :: %__MODULE__{
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil,
          bundle_id: String.t() | nil,
          app_apple_id: integer() | nil,
          data: [SubscriptionGroupIdentifierItem.t()] | nil
        }

  defstruct [
    :environment,
    :raw_environment,
    :bundle_id,
    :app_apple_id,
    :data
  ]
end
