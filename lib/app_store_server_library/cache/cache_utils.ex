defmodule AppStoreServerLibrary.Cache.CacheUtils do
  @moduledoc """
  Shared cache utilities for GenServer-based caches.

  This module provides common functions for cache management including
  TTL-based expiration and LRU-style eviction when capacity is reached.

  ## Usage

  Include this module in your cache GenServer:

      defmodule MyCache do
        use GenServer
        import AppStoreServerLibrary.Cache.CacheUtils

        # Use clean_expired/2 and evict_oldest/1 in your handle_* callbacks
      end

  """

  @doc """
  Removes expired entries from the cache.

  Takes a cache map where values are `{data, expiration}` tuples and the current
  monotonic time. Returns a new map with only non-expired entries.

  ## Parameters

    * `cache` - Map of `{key, {value, expiration}}` entries
    * `now` - Current time in seconds (monotonic)

  ## Examples

      cache = %{key1: {"value1", 100}, key2: {"value2", 50}}
      clean_expired(cache, 75)
      #=> %{key1: {"value1", 100}}

  """
  @spec clean_expired(map(), integer()) :: map()
  def clean_expired(cache, now) do
    cache
    |> Enum.filter(fn {_key, {_value, expiration}} -> expiration > now end)
    |> Map.new()
  end

  @doc """
  Evicts the oldest entry (earliest expiration) from the cache.

  Returns the cache unchanged if it's empty.

  ## Parameters

    * `cache` - Map of `{key, {value, expiration}}` entries

  ## Examples

      cache = %{key1: {"value1", 100}, key2: {"value2", 50}}
      evict_oldest(cache)
      #=> %{key1: {"value1", 100}}

  """
  @spec evict_oldest(map()) :: map()
  def evict_oldest(cache) when map_size(cache) == 0, do: cache

  def evict_oldest(cache) do
    {oldest_key, _} =
      cache
      |> Enum.min_by(fn {_key, {_value, expiration}} -> expiration end)

    Map.delete(cache, oldest_key)
  end

  @doc """
  Ensures cache is within capacity, cleaning expired entries and evicting if needed.

  First attempts to clean expired entries. If still at capacity, evicts the oldest entry.

  ## Parameters

    * `cache` - Map of `{key, {value, expiration}}` entries
    * `max_size` - Maximum number of entries allowed
    * `now` - Current time in seconds (monotonic)

  ## Returns

  A cache map that is guaranteed to have fewer than `max_size` entries.

  """
  @spec ensure_capacity(map(), pos_integer(), integer()) :: map()
  def ensure_capacity(cache, max_size, now) do
    cache =
      if map_size(cache) >= max_size do
        clean_expired(cache, now)
      else
        cache
      end

    if map_size(cache) >= max_size do
      evict_oldest(cache)
    else
      cache
    end
  end
end
