defmodule AppStoreServerLibrary.Models.AdvancedCommerceTransactionItem do
  @moduledoc """
  An item in an Advanced Commerce subscription transaction.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetransactionitem
  """

  alias AppStoreServerLibrary.Models.{AdvancedCommerceOffer, AdvancedCommerceRefund}
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          sku: String.t() | nil,
          description: String.t() | nil,
          display_name: String.t() | nil,
          offer: AdvancedCommerceOffer.t() | nil,
          price: integer() | nil,
          refunds: [AdvancedCommerceRefund.t()] | nil,
          revocation_date: integer() | nil
        }

  defstruct [
    :sku,
    :description,
    :display_name,
    :offer,
    :price,
    :refunds,
    :revocation_date
  ]

  @doc """
  Creates a new AdvancedCommerceTransactionItem struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"sku", :string},
             {"description", :string},
             {"display_name", :string},
             {"offer", :map},
             {"price", :integer},
             {"refunds", :list},
             {"revocation_date", :integer}
           ]),
         {:ok, offer} <- build_offer(Map.get(map, :offer)),
         {:ok, refunds} <- build_refunds(Map.get(map, :refunds)) do
      {:ok,
       struct(__MODULE__, %{
         sku: Map.get(map, :sku),
         description: Map.get(map, :description),
         display_name: Map.get(map, :display_name),
         offer: offer,
         price: Map.get(map, :price),
         refunds: refunds,
         revocation_date: Map.get(map, :revocation_date)
       })}
    end
  end

  defp build_offer(nil), do: {:ok, nil}

  defp build_offer(%{} = offer_map) do
    case AdvancedCommerceOffer.new(offer_map) do
      {:ok, offer} -> {:ok, offer}
      {:error, _} = err -> err
    end
  end

  defp build_offer(_), do: {:error, {:verification_failure, "Invalid map field: offer"}}

  defp build_refunds(nil), do: {:ok, nil}

  defp build_refunds(refund_list) when is_list(refund_list) do
    refund_list
    |> Enum.reduce_while({:ok, []}, fn refund_map, {:ok, acc} ->
      case AdvancedCommerceRefund.new(refund_map) do
        {:ok, refund} -> {:cont, {:ok, [refund | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, refunds} -> {:ok, Enum.reverse(refunds)}
      error -> error
    end
  end

  defp build_refunds(_), do: {:error, {:verification_failure, "Invalid list field: refunds"}}

  defp normalize_keys(map) do
    if map |> Map.keys() |> List.first() |> is_binary() do
      JSON.keys_to_atoms(map)
    else
      map
    end
  end
end
