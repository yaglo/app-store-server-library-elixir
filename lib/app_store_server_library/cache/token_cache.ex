defmodule AppStoreServerLibrary.Cache.TokenCache do
  @moduledoc """
  GenServer for caching JWT tokens used for App Store Server API authentication.

  This cache stores generated JWT tokens to avoid regenerating them for every
  API request. Tokens are cached per client configuration (key_id + issuer_id + bundle_id)
  and automatically expire before the JWT's own expiration.

  ## Token Lifecycle

  - JWT tokens are generated with a 5-minute expiration (as per Apple's spec)
  - Cached tokens are considered valid for 4 minutes (1 minute safety margin)
  - When a cached token is within 1 minute of expiration, a new one is generated

  ## Usage

  The cache is automatically used by `AppStoreServerAPIClient`. You don't need
  to interact with this module directly.

  ## Configuration

      config :app_store_server_library,
        token_cache_ttl_seconds: 240,  # 4 minutes (tokens expire at 5 min)
        token_cache_max_size: 100      # Maximum number of cached tokens
  """

  use GenServer

  import AppStoreServerLibrary.Cache.CacheUtils

  # JWT expires after 5 minutes, cache for 4 minutes (60 second safety margin)
  @default_ttl_seconds 4 * 60
  @default_max_size 100

  # Client API

  @doc """
  Starts the token cache.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Gets or generates a JWT token for the given client configuration.

  If a valid cached token exists, it is returned. Otherwise, the provided
  `generate_fn` is called to create a new token, which is then cached.

  ## Parameters

  - `client_key` - A tuple of `{key_id, issuer_id, bundle_id}` identifying the client
  - `generate_fn` - A zero-arity function that generates a new JWT token

  ## Returns

  The JWT token string.
  """
  @spec get_or_generate(
          {String.t(), String.t(), String.t()},
          (-> String.t()),
          GenServer.server()
        ) :: String.t()
  def get_or_generate(client_key, generate_fn, server \\ __MODULE__) do
    GenServer.call(server, {:get_or_generate, client_key, generate_fn})
  end

  @doc """
  Invalidates the cached token for a specific client.

  Useful when you need to force token regeneration, such as after
  receiving an authentication error from the API.
  """
  @spec invalidate({String.t(), String.t(), String.t()}, GenServer.server()) :: :ok
  def invalidate(client_key, server \\ __MODULE__) do
    GenServer.cast(server, {:invalidate, client_key})
  end

  @doc """
  Clears all cached tokens.

  Useful for testing or when credentials are rotated.
  """
  @spec clear(GenServer.server()) :: :ok
  def clear(server \\ __MODULE__) do
    GenServer.call(server, :clear)
  end

  @doc """
  Returns the current cache stats.
  """
  @spec stats(GenServer.server()) :: %{size: non_neg_integer(), max_size: pos_integer()}
  def stats(server \\ __MODULE__) do
    GenServer.call(server, :stats)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    ttl_seconds =
      Application.get_env(
        :app_store_server_library,
        :token_cache_ttl_seconds,
        @default_ttl_seconds
      )

    max_size =
      Application.get_env(
        :app_store_server_library,
        :token_cache_max_size,
        @default_max_size
      )

    state = %{
      cache: %{},
      ttl_seconds: ttl_seconds,
      max_size: max_size
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get_or_generate, client_key, generate_fn}, _from, state) do
    now = System.monotonic_time(:second)

    case Map.get(state.cache, client_key) do
      {token, expiration} when expiration > now ->
        # Valid cached token
        {:reply, token, state}

      _ ->
        # No token or expired - generate new one
        token = generate_fn.()
        expiration = now + state.ttl_seconds

        cache = ensure_capacity(state.cache, state.max_size, now)
        new_cache = Map.put(cache, client_key, {token, expiration})
        {:reply, token, %{state | cache: new_cache}}
    end
  end

  @impl true
  def handle_call(:clear, _from, state) do
    {:reply, :ok, %{state | cache: %{}}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    stats = %{
      size: map_size(state.cache),
      max_size: state.max_size
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_cast({:invalidate, client_key}, state) do
    new_cache = Map.delete(state.cache, client_key)
    {:noreply, %{state | cache: new_cache}}
  end
end
