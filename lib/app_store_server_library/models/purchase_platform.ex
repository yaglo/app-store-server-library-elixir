defmodule AppStoreServerLibrary.Models.PurchasePlatform do
  @moduledoc """
  Values that represent Apple platforms.

  https://developer.apple.com/documentation/storekit/appstore/platform
  """

  @type t() :: :ios | :mac_os | :tv_os | :vision_os

  @doc """
  Convert string to atom
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_platform}
  def from_string("iOS"), do: {:ok, :ios}
  def from_string("macOS"), do: {:ok, :mac_os}
  def from_string("tvOS"), do: {:ok, :tv_os}
  def from_string("visionOS"), do: {:ok, :vision_os}
  def from_string(_), do: {:error, :invalid_platform}

  @doc """
  Convert atom to string
  """
  @spec to_string(t()) :: String.t()
  def to_string(:ios), do: "iOS"
  def to_string(:mac_os), do: "macOS"
  def to_string(:tv_os), do: "tvOS"
  def to_string(:vision_os), do: "visionOS"
end
