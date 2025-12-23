defmodule AppStoreServerLibrary.Cache.CertificateCache do
  @moduledoc """
  GenServer for caching verified certificate public keys.

  This cache stores the public keys extracted from verified certificate chains,
  avoiding repeated chain verification and OCSP checks for the same certificates.

  The cache is shared across all requests and uses the same parameters as
  Apple's official implementations:
  - Maximum 32 entries (default)
  - 15 minute TTL

  ## Usage

  The cache is automatically used by `ChainVerifier` when online checks are enabled.
  You don't need to interact with this module directly.

  ## Configuration

      config :app_store_server_library,
        certificate_cache_max_size: 32,
        certificate_cache_ttl_seconds: 900

  ## Memory Considerations

  Each cache entry stores a PEM-encoded public key (typically ~200-400 bytes) plus
  the cache key hash (32 bytes). With the default maximum of 32 entries, memory
  usage is bounded to approximately 15-20 KB.

  If you increase `certificate_cache_max_size` significantly, monitor your
  application's memory usage. For most applications, the default of 32 entries
  provides excellent cache hit rates while keeping memory usage minimal.

  The cache automatically evicts expired entries when the capacity limit is reached,
  prioritizing removal of the oldest expired entries first.
  """

  use GenServer

  import AppStoreServerLibrary.Cache.CacheUtils

  @default_max_size 32
  @default_ttl_seconds 15 * 60

  # Client API

  @doc """
  Starts the certificate cache.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Gets a cached public key for the given certificates.

  Returns `{:ok, public_key_pem}` if found and not expired, `:miss` otherwise.
  """
  @spec get([String.t()], GenServer.server()) :: {:ok, String.t()} | :miss
  def get(certificates, server \\ __MODULE__) do
    GenServer.call(server, {:get, certificates})
  end

  @doc """
  Stores a verified public key in the cache.

  The entry will expire after the configured TTL.
  """
  @spec put([String.t()], String.t(), GenServer.server()) :: :ok
  def put(certificates, public_key_pem, server \\ __MODULE__) do
    GenServer.cast(server, {:put, certificates, public_key_pem})
  end

  @doc """
  Clears all entries from the cache.

  Useful for testing or when root certificates are updated.
  """
  @spec clear(GenServer.server()) :: :ok
  def clear(server \\ __MODULE__) do
    GenServer.call(server, :clear)
  end

  @doc """
  Returns the current cache stats.

  Returns a map with `:size` and `:max_size`.
  """
  @spec stats(GenServer.server()) :: %{size: non_neg_integer(), max_size: pos_integer()}
  def stats(server \\ __MODULE__) do
    GenServer.call(server, :stats)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    max_size =
      Application.get_env(
        :app_store_server_library,
        :certificate_cache_max_size,
        @default_max_size
      )

    ttl_seconds =
      Application.get_env(
        :app_store_server_library,
        :certificate_cache_ttl_seconds,
        @default_ttl_seconds
      )

    state = %{
      cache: %{},
      max_size: max_size,
      ttl_seconds: ttl_seconds
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get, certificates}, _from, state) do
    cache_key = compute_cache_key(certificates)
    now = System.monotonic_time(:second)

    result =
      case Map.get(state.cache, cache_key) do
        nil ->
          :miss

        {public_key, expiration} when expiration > now ->
          {:ok, public_key}

        _ ->
          # Expired entry
          :miss
      end

    {:reply, result, state}
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
  def handle_cast({:put, certificates, public_key_pem}, state) do
    cache_key = compute_cache_key(certificates)
    now = System.monotonic_time(:second)
    expiration = now + state.ttl_seconds

    cache = ensure_capacity(state.cache, state.max_size, now)
    new_cache = Map.put(cache, cache_key, {public_key_pem, expiration})
    {:noreply, %{state | cache: new_cache}}
  end

  # Private helpers

  defp compute_cache_key(certificates) do
    :crypto.hash(:sha256, :erlang.term_to_binary(certificates))
  end
end
