defmodule AppStoreServerLibrary.Models.MassExtendRenewalDateStatusResponse do
  @moduledoc """
  Response for checking the status of mass renewal date extensions.
  """

  defstruct [
    :request_uuid,
    :request_identifier,
    :status,
    :complete,
    :complete_date,
    :succeeded_count,
    :failed_count
  ]

  @type t :: %__MODULE__{
          request_uuid: String.t() | nil,
          request_identifier: String.t() | nil,
          status: String.t() | nil,
          complete: boolean() | nil,
          complete_date: integer() | nil,
          succeeded_count: integer() | nil,
          failed_count: integer() | nil
        }
end
