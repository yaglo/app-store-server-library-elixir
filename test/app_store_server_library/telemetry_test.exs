defmodule AppStoreServerLibrary.TelemetryTest do
  use ExUnit.Case, async: false

  alias AppStoreServerLibrary.Telemetry

  setup do
    test_pid = self()
    handler_id = "test-handler-#{:erlang.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      [
        [:app_store_server_library, :test, :start],
        [:app_store_server_library, :test, :stop],
        [:app_store_server_library, :test, :exception]
      ],
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  describe "Telemetry.span/3" do
    test "emits start and stop events on success" do
      result =
        Telemetry.span([:app_store_server_library, :test], %{foo: :bar}, fn ->
          :success_result
        end)

      assert result == :success_result

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :start],
                      %{system_time: system_time}, %{foo: :bar}}

      assert is_integer(system_time)

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :stop],
                      %{duration: duration}, %{foo: :bar}}

      assert is_integer(duration)
      assert duration >= 0
    end

    test "emits exception event on error" do
      assert_raise RuntimeError, "test error", fn ->
        Telemetry.span([:app_store_server_library, :test], %{operation: :failing}, fn ->
          raise "test error"
        end)
      end

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :start], _, _}

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :exception],
                      %{duration: duration},
                      %{operation: :failing, kind: :error, reason: %RuntimeError{}}}

      assert is_integer(duration)
    end

    test "emits exception event on throw" do
      catch_throw do
        Telemetry.span([:app_store_server_library, :test], %{operation: :throwing}, fn ->
          throw(:test_throw)
        end)
      end

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :start], _, _}

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :exception],
                      %{duration: _}, %{operation: :throwing, kind: :throw, reason: :test_throw}}
    end

    test "emits exception event on exit" do
      catch_exit do
        Telemetry.span([:app_store_server_library, :test], %{operation: :exiting}, fn ->
          exit(:test_exit)
        end)
      end

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :start], _, _}

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :exception],
                      %{duration: _}, %{operation: :exiting, kind: :exit, reason: :test_exit}}
    end

    test "preserves return value" do
      result =
        Telemetry.span([:app_store_server_library, :test], %{}, fn ->
          {:ok, %{data: "test"}}
        end)

      assert result == {:ok, %{data: "test"}}
    end

    test "measures duration correctly" do
      Telemetry.span([:app_store_server_library, :test], %{}, fn ->
        Process.sleep(10)
        :ok
      end)

      assert_receive {:telemetry_event, [:app_store_server_library, :test, :stop],
                      %{duration: duration}, _}

      # Duration should be at least 10ms in native time units
      duration_ms = System.convert_time_unit(duration, :native, :millisecond)
      assert duration_ms >= 10
    end
  end

  describe "Integration with verification modules" do
    setup do
      test_pid = self()
      handler_id = "verification-test-handler-#{:erlang.unique_integer([:positive])}"

      :telemetry.attach_many(
        handler_id,
        [
          [:app_store_server_library, :verification, :signature, :start],
          [:app_store_server_library, :verification, :signature, :stop],
          [:app_store_server_library, :verification, :chain, :start],
          [:app_store_server_library, :verification, :chain, :stop]
        ],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry_event, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      :ok
    end

    test "signature verification emits telemetry events" do
      alias AppStoreServerLibrary.Verification.SignedDataVerifier

      {:ok, verifier} =
        SignedDataVerifier.new(
          root_certificates: [],
          environment: :local_testing,
          bundle_id: "com.example"
        )

      # Create a mock JWS token
      header = %{"alg" => "ES256", "x5c" => ["mock"]}
      payload = %{"environment" => "LocalTesting", "bundleId" => "com.example"}
      header_b64 = Base.url_encode64(Jason.encode!(header), padding: false)
      payload_b64 = Base.url_encode64(Jason.encode!(payload), padding: false)
      signature_b64 = Base.url_encode64("mock", padding: false)
      signed_payload = "#{header_b64}.#{payload_b64}.#{signature_b64}"

      # This will succeed for local_testing (skips signature verification)
      _result = SignedDataVerifier.verify_and_decode_notification(verifier, signed_payload)

      # Should receive telemetry events
      assert_receive {:telemetry_event,
                      [:app_store_server_library, :verification, :signature, :start],
                      %{system_time: _}, %{type: :notification}}

      assert_receive {:telemetry_event,
                      [:app_store_server_library, :verification, :signature, :stop],
                      %{duration: _}, %{type: :notification}}
    end

    test "chain verification emits telemetry events" do
      alias AppStoreServerLibrary.Verification.ChainVerifier

      root_ca_base64 =
        "MIIBgjCCASmgAwIBAgIJALUc5ALiH5pbMAoGCCqGSM49BAMDMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlDdXBlcnRpbm8wHhcNMjMwMTA1MjEzMDIyWhcNMzMwMTAyMjEzMDIyWjA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEc+/Bl+gospo6tf9Z7io5tdKdrlN1YdVnqEhEDXDShzdAJPQijamXIMHf8xWWTa1zgoYTxOKpbuJtDplz1XriTaMgMB4wDAYDVR0TBAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZIzj0EAwMDRwAwRAIgemWQXnMAdTad2JDJWng9U4uBBL5mA7WI05H7oH7c6iQCIHiRqMjNfzUAyiu9h6rOU/K+iTR0I/3Y/NSWsXHX+acc"

      intermediate_ca_base64 =
        "MIIBnzCCAUWgAwIBAgIBCzAKBggqhkjOPQQDAzA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMB4XDTIzMDEwNTIxMzEwNVoXDTMzMDEwMTIxMzEwNVowRTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xFTATBgNVBAoMDEludGVybWVkaWF0ZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBUN5V9rKjfRiMAIojEA0Av5Mp0oF+O0cL4gzrTF178inUHugj7Et46NrkQ7hKgMVnjogq45Q1rMs+cMHVNILWqjNTAzMA8GA1UdEwQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAgEEAgUAMAoGCCqGSM49BAMDA0gAMEUCIQCmsIKYs41ullssHX4rVveUT0Z7Is5/hLK1lFPTtun3hAIgc2+2RG5+gNcFVcs+XJeEl4GZ+ojl3ROOmll+ye7dynQ="

      leaf_cert_base64 =
        "MIIBoDCCAUagAwIBAgIBDDAKBggqhkjOPQQDAzBFMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCUN1cGVydGlubzEVMBMGA1UECgwMSW50ZXJtZWRpYXRlMB4XDTIzMDEwNTIxMzEzNFoXDTMzMDEwMTIxMzEzNFowPTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xDTALBgNVBAoMBExlYWYwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATitYHEaYVuc8g9AjTOwErMvGyPykPa+puvTI8hJTHZZDLGas2qX1+ErxgQTJgVXv76nmLhhRJH+j25AiAI8iGsoy8wLTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsBBAIFADAKBggqhkjOPQQDAwNIADBFAiBX4c+T0Fp5nJ5QRClRfu5PSByRvNPtuaTsk0vPB3WAIAIhANgaauAj/YP9s0AkEhyJhxQO/6Q2zouZ+H1CIOehnMzQ"

      root_der = Base.decode64!(root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      _result =
        ChainVerifier.verify_chain(
          verifier,
          [leaf_cert_base64, intermediate_ca_base64, root_ca_base64],
          false,
          1_761_962_975
        )

      # Should receive chain verification telemetry events
      assert_receive {:telemetry_event,
                      [:app_store_server_library, :verification, :chain, :start],
                      %{system_time: _}, %{cert_count: 3, online_checks: false}}

      assert_receive {:telemetry_event, [:app_store_server_library, :verification, :chain, :stop],
                      %{duration: _}, %{cert_count: 3, online_checks: false}}
    end
  end
end
