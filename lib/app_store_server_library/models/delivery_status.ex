defmodule AppStoreServerLibrary.Models.DeliveryStatus do
  @moduledoc """
  A value that indicates whether the app successfully delivered an in-app purchase that works properly.

  https://developer.apple.com/documentation/appstoreserverapi/deliverystatus
  """

  @type t ::
          :delivered_and_working_properly
          | :did_not_deliver_due_to_quality_issue
          | :delivered_wrong_item
          | :did_not_deliver_due_to_server_outage
          | :did_not_deliver_due_to_in_game_currency_change
          | :did_not_deliver_for_other_reason

  @doc """
  Convert integer to delivery status atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :delivered_and_working_properly
  def from_integer(1), do: :did_not_deliver_due_to_quality_issue
  def from_integer(2), do: :delivered_wrong_item
  def from_integer(3), do: :did_not_deliver_due_to_server_outage
  def from_integer(4), do: :did_not_deliver_due_to_in_game_currency_change
  def from_integer(5), do: :did_not_deliver_for_other_reason

  @doc """
  Convert delivery status atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:delivered_and_working_properly), do: 0
  def to_integer(:did_not_deliver_due_to_quality_issue), do: 1
  def to_integer(:delivered_wrong_item), do: 2
  def to_integer(:did_not_deliver_due_to_server_outage), do: 3
  def to_integer(:did_not_deliver_due_to_in_game_currency_change), do: 4
  def to_integer(:did_not_deliver_for_other_reason), do: 5
end
