defmodule AppStoreServerLibrary.Models.TransactionReason do
  @moduledoc """
  The cause of a purchase transaction, which indicates whether it's a customer's purchase or a renewal for an auto-renewable subscription that the system initiates.

  https://developer.apple.com/documentation/appstoreserverapi/transactionreason
  """

  @type t :: :purchase | :renewal

  @doc """
  Transaction reason values
  """
  def purchase, do: :purchase
  def renewal, do: :renewal

  @doc """
  Convert string to atom
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_transaction_reason}
  def from_string("PURCHASE"), do: {:ok, :purchase}
  def from_string("RENEWAL"), do: {:ok, :renewal}
  def from_string(_), do: {:error, :invalid_transaction_reason}

  @doc """
  Convert atom to string representation
  """
  @spec to_string(t()) :: String.t()
  def to_string(:purchase), do: "PURCHASE"
  def to_string(:renewal), do: "RENEWAL"
end
