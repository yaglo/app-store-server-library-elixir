defmodule AppStoreServerLibrary.Models.Environment do
  @moduledoc """
  The server environment, either sandbox or production.

  https://developer.apple.com/documentation/appstoreserverapi/environment
  """

  @type t :: :sandbox | :production | :xcode | :local_testing | String.t()

  @doc """
  Allowed environment values for validation (atoms and their string forms).
  """
  @spec allowed_values() :: [atom() | String.t()]
  def allowed_values do
    [
      :sandbox,
      :production,
      :xcode,
      :local_testing,
      "Sandbox",
      "Production",
      "Xcode",
      "LocalTesting"
    ]
  end

  @doc """
  Convert string to environment atom.
  Returns the original string if the value is not recognized (forward compatibility).
  """
  @spec from_string(String.t()) :: t()
  def from_string("Sandbox"), do: :sandbox
  def from_string("Production"), do: :production
  def from_string("Xcode"), do: :xcode
  def from_string("LocalTesting"), do: :local_testing
  def from_string(unknown) when is_binary(unknown), do: unknown

  @doc """
  Convert environment atom to string
  """
  @spec to_string(t()) :: String.t()
  def to_string(:sandbox), do: "Sandbox"
  def to_string(:production), do: "Production"
  def to_string(:xcode), do: "Xcode"
  def to_string(:local_testing), do: "LocalTesting"
  def to_string(unknown) when is_binary(unknown), do: unknown
end
