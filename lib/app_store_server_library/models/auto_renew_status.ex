defmodule AppStoreServerLibrary.Models.AutoRenewStatus do
  @moduledoc """
  The renewal status for an auto-renewable subscription.

  https://developer.apple.com/documentation/appstoreserverapi/autorenewstatus
  """

  @type t :: :off | :on

  @doc """
  Auto renew status values
  """
  def off, do: :off
  def on, do: :on

  @doc """
  Convert integer to atom
  """
  @spec from_integer(integer()) :: {:ok, t()} | {:error, :invalid_auto_renew_status}
  def from_integer(0), do: {:ok, :off}
  def from_integer(1), do: {:ok, :on}
  def from_integer(_), do: {:error, :invalid_auto_renew_status}

  @doc """
  Convert atom to integer representation
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:off), do: 0
  def to_integer(:on), do: 1
end
