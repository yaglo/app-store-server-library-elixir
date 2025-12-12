defmodule AppStoreServerLibrary.Models.ImageState do
  @moduledoc """
  The approval state of an image.

  https://developer.apple.com/documentation/retentionmessaging/imagestate
  """

  @type t() :: :pending | :approved | :rejected

  @doc """
  Convert string to atom
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_state}
  def from_string("PENDING"), do: {:ok, :pending}
  def from_string("APPROVED"), do: {:ok, :approved}
  def from_string("REJECTED"), do: {:ok, :rejected}
  def from_string(_), do: {:error, :invalid_state}

  @doc """
  Convert atom to string
  """
  @spec to_string(t()) :: String.t()
  def to_string(:pending), do: "PENDING"
  def to_string(:approved), do: "APPROVED"
  def to_string(:rejected), do: "REJECTED"
end
