defmodule AppStoreServerLibrary.Models.InAppOwnershipType do
  @moduledoc """
  The relationship of the user with a family-shared purchase to which they have access.

  https://developer.apple.com/documentation/appstoreserverapi/inappownershiptype
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:family_shared, "FAMILY_SHARED")
    value(:purchased, "PURCHASED")
  end
end
