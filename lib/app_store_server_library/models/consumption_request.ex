defmodule AppStoreServerLibrary.Models.ConsumptionRequest do
  @moduledoc """
  The request body containing consumption information.

  https://developer.apple.com/documentation/appstoreserverapi/consumptionrequest
  """

  alias AppStoreServerLibrary.Models.{DeliveryStatus, RefundPreference}
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          customer_consented: boolean(),
          delivery_status: DeliveryStatus.t(),
          sample_content_provided: boolean(),
          consumption_percentage: non_neg_integer() | nil,
          refund_preference: RefundPreference.t() | nil
        }

  @enforce_keys [:customer_consented, :delivery_status, :sample_content_provided]
  defstruct [
    :customer_consented,
    :delivery_status,
    :sample_content_provided,
    :consumption_percentage,
    :refund_preference
  ]

  @doc """
  Creates a new ConsumptionRequest struct from a map with camelCase or snake_case keys.

  ## Required Fields

    * `:customer_consented` - Boolean indicating customer consented to share data
    * `:delivery_status` - The delivery status of the in-app purchase (atom or string)
    * `:sample_content_provided` - Boolean indicating if sample content was provided

  ## Optional Fields

    * `:consumption_percentage` - The percentage of consumption (0-100000, where 100000 = 100%)
    * `:refund_preference` - The refund preference (atom or string)

  ## Examples

      iex> ConsumptionRequest.new(%{
      ...>   customer_consented: true,
      ...>   delivery_status: :delivered,
      ...>   sample_content_provided: false
      ...> })
      {:ok, %ConsumptionRequest{...}}

  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = JSON.keys_to_atoms(map)

    with :ok <- validate_required_fields(map),
         :ok <-
           Validator.optional_fields(map, [
             {"consumption_percentage", :integer},
             {"refund_preference", :any}
           ]),
         {:ok, map} <- parse_delivery_status(map),
         {:ok, map} <- parse_refund_preference(map) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  defp validate_required_fields(map) do
    with :ok <- validate_required(:customer_consented, map),
         :ok <- validate_required(:delivery_status, map),
         :ok <- validate_required(:sample_content_provided, map),
         :ok <- validate_boolean(:customer_consented, map) do
      validate_boolean(:sample_content_provided, map)
    end
  end

  defp validate_required(field, map) do
    if Map.has_key?(map, field) do
      :ok
    else
      {:error, {:validation_error, "#{field} is required"}}
    end
  end

  defp validate_boolean(field, map) do
    case Map.get(map, field) do
      value when is_boolean(value) -> :ok
      _ -> {:error, {:validation_error, "#{field} must be a boolean"}}
    end
  end

  defp parse_delivery_status(map) do
    case Map.get(map, :delivery_status) do
      value when is_atom(value) ->
        {:ok, map}

      value when is_binary(value) ->
        {:ok, Map.put(map, :delivery_status, DeliveryStatus.from_string(value))}

      value ->
        {:error,
         {:validation_error, "delivery_status must be an atom or string, got: #{inspect(value)}"}}
    end
  end

  defp parse_refund_preference(map) do
    case Map.get(map, :refund_preference) do
      nil ->
        {:ok, map}

      value when is_atom(value) ->
        {:ok, map}

      value when is_binary(value) ->
        {:ok, Map.put(map, :refund_preference, RefundPreference.from_string(value))}

      value ->
        {:error,
         {:validation_error,
          "refund_preference must be an atom or string, got: #{inspect(value)}"}}
    end
  end

  defimpl Jason.Encoder do
    def encode(request, opts) do
      request
      |> Map.from_struct()
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> {k, convert_value(k, v)} end)
      |> Map.new()
      |> JSON.keys_to_camel()
      |> Jason.Encode.map(opts)
    end

    defp convert_value(:delivery_status, v), do: DeliveryStatus.to_string(v)
    defp convert_value(:refund_preference, v), do: RefundPreference.to_string(v)
    defp convert_value(_k, v), do: v
  end
end
