defmodule AppStoreServerLibrary.TestUtil do
  @moduledoc """
  Test utilities for App Store Server Library tests.

  This module provides helper functions for testing, matching the functionality
  of the Python util.py module.
  """

  alias AppStoreServerLibrary.Models.Environment
  alias AppStoreServerLibrary.Verification.SignedDataVerifier
  alias JOSE.{JWK, JWS}

  @doc """
  Creates signed data from a JSON file, similar to the Python create_signed_data_from_json function.

  ## Parameters
  - path: Path to the JSON file containing the payload

  ## Returns
  - JWS signed token as a string
  """
  def create_signed_data_from_json(path) do
    # Read JSON data from file
    data = read_data_from_file(path)
    decoded_data = Jason.decode!(data)

    # Generate a test EC key pair
    {private_key, _public_key} = :crypto.generate_key(:ecdh, :secp256r1)
    jwk = JWK.from_oct(private_key)

    # Sign the data
    jws = JWS.sign(jwk, decoded_data, %{"alg" => "ES256"})
    {_, signed_token} = JWS.compact(jws)

    signed_token
  end

  @doc """
  Decodes JSON from signed data without verification, similar to the Python decode_json_from_signed_date function.

  ## Parameters
  - data: Signed JWT token

  ## Returns
  - Map containing header, payload, and signature
  """
  def decode_json_from_signed_date(data) do
    # Generate a test public key (we don't care about verification for this)
    {private_key, _public_key} = :crypto.generate_key(:ecdh, :secp256r1)
    jwk = JWK.from_oct(private_key)

    # Decode without verification
    JWS.verify_strict(jwk, ["ES256"], data)
  end

  @doc """
  Reads data from a text file, similar to the Python read_data_from_file function.

  ## Parameters
  - path: Path to the file

  ## Returns
  - File contents as a string
  """
  def read_data_from_file(path) do
    File.read!(path)
  end

  @doc """
  Reads data from a binary file, similar to the Python read_data_from_binary_file function.

  ## Parameters
  - path: Path to the file

  ## Returns
  - File contents as binary
  """
  def read_data_from_binary_file(path) do
    File.read!(path)
  end

  @doc """
  Creates a SignedDataVerifier with test parameters, similar to the Python get_signed_data_verifier function.

  ## Parameters
  - env: Environment enum value
  - bundle_id: Bundle ID string
  - app_apple_id: App Apple ID (optional, defaults to 1234)

  ## Returns
  - SignedDataVerifier struct
  """
  def get_signed_data_verifier(env, bundle_id, app_apple_id \\ 1234) do
    root_ca_cert = read_data_from_binary_file("test/resources/certs/testCA.der")

    # Create verifier with test certificates
    verifier = %SignedDataVerifier{
      root_certificates: [root_ca_cert],
      online_checks: false,
      environment: env,
      bundle_id: bundle_id,
      app_apple_id: app_apple_id
    }

    # Note: In the Python version, they disable strict checks on chain verifier
    # We would need to implement similar functionality if we have chain verification
    verifier
  end

  @doc """
  Creates a default SignedDataVerifier for testing, similar to the Python get_default_signed_data_verifier function.

  ## Returns
  - SignedDataVerifier configured for local testing with com.example bundle ID
  """
  def get_default_signed_data_verifier do
    get_signed_data_verifier(Environment.local_testing(), "com.example")
  end

  @doc """
  Gets the signing key for testing, similar to the Python get_signing_key function.

  ## Returns
  - Private key data from test certificate
  """
  def get_signing_key do
    read_data_from_binary_file("test/resources/certs/testSigningKey.p8")
  end
end
