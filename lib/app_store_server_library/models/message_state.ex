defmodule AppStoreServerLibrary.Models.MessageState do
  @moduledoc """
  The approval state of the message.

  https://developer.apple.com/documentation/retentionmessaging/messagestate
  """

  @type t :: :pending | :approved | :rejected

  @doc """
  Converts a string value to the corresponding atom.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :unknown_value}
  def from_string("PENDING"), do: {:ok, :pending}
  def from_string("APPROVED"), do: {:ok, :approved}
  def from_string("REJECTED"), do: {:ok, :rejected}
  def from_string(_), do: {:error, :unknown_value}

  @doc """
  Converts an atom to its string representation.
  """
  @spec to_string(t()) :: String.t()
  def to_string(:pending), do: "PENDING"
  def to_string(:approved), do: "APPROVED"
  def to_string(:rejected), do: "REJECTED"

  @doc """
  Returns all possible values.
  """
  @spec values() :: [t()]
  def values, do: [:pending, :approved, :rejected]
end
