defmodule AppStoreServerLibrary.Models.UserStatus do
  @moduledoc """
  The status of a customer's account within your app.

  https://developer.apple.com/documentation/appstoreserverapi/userstatus
  """

  @type t :: :undeclared | :active | :suspended | :terminated | :limited_access

  @doc """
  Convert integer to user status atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :active
  def from_integer(2), do: :suspended
  def from_integer(3), do: :terminated
  def from_integer(4), do: :limited_access

  @doc """
  Convert user status atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:active), do: 1
  def to_integer(:suspended), do: 2
  def to_integer(:terminated), do: 3
  def to_integer(:limited_access), do: 4
end
