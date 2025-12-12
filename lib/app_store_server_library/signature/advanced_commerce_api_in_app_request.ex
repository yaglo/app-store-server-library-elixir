defmodule AppStoreServerLibrary.Signature.AdvancedCommerceAPIInAppRequest do
  @moduledoc """
  Behavior for Advanced Commerce API in-app requests.

  Any struct that implements this behavior can be signed using
  AdvancedCommerceAPIInAppSignatureCreator.
  """

  @doc """
  Convert the request to a map for JSON serialization.
  """
  @callback to_map(struct()) :: map()
end
