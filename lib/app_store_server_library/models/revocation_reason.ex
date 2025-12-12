defmodule AppStoreServerLibrary.Models.RevocationReason do
  @moduledoc """
  The reason for a refunded transaction.

  https://developer.apple.com/documentation/appstoreserverapi/revocationreason
  """

  @type t() :: :refunded_for_other_reason | :refunded_due_to_issue

  @doc """
  Convert integer to atom
  """
  @spec from_integer(integer()) :: {:ok, t()} | {:error, :invalid_reason}
  def from_integer(0), do: {:ok, :refunded_for_other_reason}
  def from_integer(1), do: {:ok, :refunded_due_to_issue}
  def from_integer(_), do: {:error, :invalid_reason}

  @doc """
  Convert atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:refunded_for_other_reason), do: 0
  def to_integer(:refunded_due_to_issue), do: 1
end
