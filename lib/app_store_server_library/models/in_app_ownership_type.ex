defmodule AppStoreServerLibrary.Models.InAppOwnershipType do
  @moduledoc """
  The relationship of the user with a family-shared purchase to which they have access.

  https://developer.apple.com/documentation/appstoreserverapi/inappownershiptype
  """

  @type t :: :family_shared | :purchased

  @doc """
  In-app ownership type values
  """
  def family_shared, do: :family_shared
  def purchased, do: :purchased

  @doc """
  Convert string to atom
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_ownership_type}
  def from_string("FAMILY_SHARED"), do: {:ok, :family_shared}
  def from_string("PURCHASED"), do: {:ok, :purchased}
  def from_string(_), do: {:error, :invalid_ownership_type}

  @doc """
  Convert atom to string representation
  """
  @spec to_string(t()) :: String.t()
  def to_string(:family_shared), do: "FAMILY_SHARED"
  def to_string(:purchased), do: "PURCHASED"
end
