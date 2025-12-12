defmodule AppStoreServerLibrary.Application do
  @moduledoc """
  OTP Application for App Store Server Library.

  This application provides supervised caching for:
  - Verified certificate public keys (ChainVerifier cache)
  - JWT tokens for API client authentication

  ## Configuration

  The application can be configured in your `config.exs`:

      config :app_store_server_library,
        # Cache settings (optional, these are defaults)
        certificate_cache_max_size: 32,
        certificate_cache_ttl_seconds: 900,  # 15 minutes
        token_cache_ttl_seconds: 240         # 4 minutes (tokens expire at 5 min)

  ## Starting the Application

  The application starts automatically when included as a dependency.
  You can also start it manually:

      {:ok, _} = Application.ensure_all_started(:app_store_server_library)

  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AppStoreServerLibrary.Cache.CertificateCache,
      AppStoreServerLibrary.Cache.TokenCache
    ]

    opts = [strategy: :one_for_one, name: AppStoreServerLibrary.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
