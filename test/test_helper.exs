Code.require_file("support/ocsp_mock.ex", __DIR__)

ExUnit.start(exclude: [:ocsp_live])

# Suppress telemetry warnings about local function handlers in tests
# (telemetry warns when anonymous functions are used as handlers for performance reasons,
# but this is fine in tests)
Logger.configure(level: :warning)

# Configure test environment
Application.put_env(:app_store_server_library, :environment, :test)

Application.put_env(
  :app_store_server_library,
  :ocsp_requester,
  AppStoreServerLibrary.TestOCSPMock
)
