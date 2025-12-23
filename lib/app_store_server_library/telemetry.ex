defmodule AppStoreServerLibrary.Telemetry do
  @moduledoc """
  Telemetry events emitted by the App Store Server Library.

  This module provides observability into the library's operations through
  `:telemetry` events. No handlers are attached by default - you can attach
  your own handlers to collect metrics, log events, or integrate with your
  observability stack.

  ## API Request Events

  ### `[:app_store_server_library, :api, :request, :start]`

  Emitted when an API request starts.

  * Measurements: `%{system_time: integer()}` - System time in native units
  * Metadata: `%{method: atom(), path: String.t()}`

  ### `[:app_store_server_library, :api, :request, :stop]`

  Emitted when an API request completes successfully.

  * Measurements: `%{duration: integer()}` - Duration in native time units
  * Metadata: `%{method: atom(), path: String.t()}`

  ### `[:app_store_server_library, :api, :request, :exception]`

  Emitted when an API request fails with an exception.

  * Measurements: `%{duration: integer()}`
  * Metadata: `%{method: atom(), path: String.t(), kind: atom(), reason: term()}`

  ## Verification Events

  ### `[:app_store_server_library, :verification, :chain, :start]`

  Emitted when certificate chain verification starts.

  * Measurements: `%{system_time: integer()}`
  * Metadata: `%{cert_count: integer(), online_checks: boolean()}`

  ### `[:app_store_server_library, :verification, :chain, :stop]`

  Emitted when certificate chain verification completes.

  * Measurements: `%{duration: integer()}`
  * Metadata: `%{cert_count: integer(), online_checks: boolean()}`

  ### `[:app_store_server_library, :verification, :signature, :start]`

  Emitted when JWS signature verification starts.

  * Measurements: `%{system_time: integer()}`
  * Metadata: `%{type: atom()}` - One of `:notification`, `:transaction`, `:renewal_info`, etc.

  ### `[:app_store_server_library, :verification, :signature, :stop]`

  Emitted when JWS signature verification completes.

  * Measurements: `%{duration: integer()}`
  * Metadata: `%{type: atom()}`

  ## JWT Generation Events

  ### `[:app_store_server_library, :jwt, :generate, :start]`

  Emitted when JWT token generation starts.

  * Measurements: `%{system_time: integer()}`
  * Metadata: `%{}`

  ### `[:app_store_server_library, :jwt, :generate, :stop]`

  Emitted when JWT token generation completes.

  * Measurements: `%{duration: integer()}`
  * Metadata: `%{}`

  ## Example Usage

  Attach a handler to log API request durations:

      :telemetry.attach(
        "my-app-store-logger",
        [:app_store_server_library, :api, :request, :stop],
        fn _event, %{duration: duration}, metadata, _config ->
          duration_ms = System.convert_time_unit(duration, :native, :millisecond)
          Logger.info("App Store API request to \#{metadata.path} took \#{duration_ms}ms")
        end,
        nil
      )

  Attach multiple handlers at once:

      :telemetry.attach_many(
        "my-app-store-metrics",
        [
          [:app_store_server_library, :api, :request, :stop],
          [:app_store_server_library, :verification, :signature, :stop]
        ],
        &MyApp.Metrics.handle_event/4,
        nil
      )
  """

  @doc """
  Executes the given function within a telemetry span.

  Emits `:start` event before execution and `:stop` event after successful
  completion. If an exception is raised, emits `:exception` event and re-raises.

  ## Parameters

  * `event_prefix` - List of atoms forming the event name prefix
  * `metadata` - Map of metadata to include with events
  * `fun` - Zero-arity function to execute

  ## Returns

  The return value of `fun`.

  ## Examples

      Telemetry.span(
        [:app_store_server_library, :api, :request],
        %{method: :get, path: "/v1/transactions"},
        fn -> make_request() end
      )
  """
  @spec span(list(atom()), map(), (-> result)) :: result when result: var
  def span(event_prefix, metadata, fun) when is_list(event_prefix) and is_function(fun, 0) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      event_prefix ++ [:start],
      %{system_time: System.system_time()},
      metadata
    )

    try do
      result = fun.()
      duration = System.monotonic_time() - start_time

      :telemetry.execute(
        event_prefix ++ [:stop],
        %{duration: duration},
        metadata
      )

      result
    rescue
      e ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          event_prefix ++ [:exception],
          %{duration: duration},
          Map.merge(metadata, %{kind: :error, reason: e})
        )

        reraise e, __STACKTRACE__
    catch
      kind, reason ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          event_prefix ++ [:exception],
          %{duration: duration},
          Map.merge(metadata, %{kind: kind, reason: reason})
        )

        # Use :erlang.raise/3 to preserve the original stacktrace for throws/exits.
        # Unlike `reraise` (which only works with exceptions), this handles all
        # catch kinds (:throw, :exit, :error) and maintains proper stack context.
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end
end
