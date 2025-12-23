defmodule AppStoreServerLibrary.Cache.CertificateCacheTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Cache.CertificateCache

  setup do
    # Start a cache with a unique name for each test
    cache_name = :"cache_#{:erlang.unique_integer([:positive])}"
    {:ok, _pid} = CertificateCache.start_link(name: cache_name)
    {:ok, cache: cache_name}
  end

  describe "get/put" do
    test "returns :miss for unknown certificates", %{cache: cache} do
      assert :miss == CertificateCache.get(["cert1", "cert2"], cache)
    end

    test "stores and retrieves cached public key", %{cache: cache} do
      certs = ["cert1", "cert2", "cert3"]
      public_key = "-----BEGIN PUBLIC KEY-----\ntest\n-----END PUBLIC KEY-----"

      CertificateCache.put(certs, public_key, cache)
      # Give the cast time to process
      :timer.sleep(10)

      assert {:ok, ^public_key} = CertificateCache.get(certs, cache)
    end

    test "different certificates return different keys", %{cache: cache} do
      certs1 = ["cert1", "cert2"]
      certs2 = ["cert3", "cert4"]
      key1 = "public_key_1"
      key2 = "public_key_2"

      CertificateCache.put(certs1, key1, cache)
      CertificateCache.put(certs2, key2, cache)
      :timer.sleep(10)

      assert {:ok, ^key1} = CertificateCache.get(certs1, cache)
      assert {:ok, ^key2} = CertificateCache.get(certs2, cache)
    end
  end

  describe "TTL expiration" do
    test "expired entries return :miss" do
      # Start cache with 1 second TTL for testing
      cache_name = :"cache_ttl_#{:erlang.unique_integer([:positive])}"

      # Temporarily set short TTL
      original_ttl =
        Application.get_env(:app_store_server_library, :certificate_cache_ttl_seconds)

      Application.put_env(:app_store_server_library, :certificate_cache_ttl_seconds, 1)

      {:ok, _pid} = CertificateCache.start_link(name: cache_name)

      certs = ["cert1", "cert2"]
      public_key = "test_key"

      CertificateCache.put(certs, public_key, cache_name)
      :timer.sleep(10)

      # Should be available immediately
      assert {:ok, ^public_key} = CertificateCache.get(certs, cache_name)

      # Wait for TTL to expire
      :timer.sleep(1100)

      # Should now be expired
      assert :miss == CertificateCache.get(certs, cache_name)

      # Restore original TTL
      if original_ttl do
        Application.put_env(
          :app_store_server_library,
          :certificate_cache_ttl_seconds,
          original_ttl
        )
      else
        Application.delete_env(:app_store_server_library, :certificate_cache_ttl_seconds)
      end
    end
  end

  describe "eviction" do
    test "evicts oldest entry when at capacity" do
      cache_name = :"cache_evict_#{:erlang.unique_integer([:positive])}"

      # Set max size to 3 for testing
      original_max_size =
        Application.get_env(:app_store_server_library, :certificate_cache_max_size)

      Application.put_env(:app_store_server_library, :certificate_cache_max_size, 3)

      {:ok, _pid} = CertificateCache.start_link(name: cache_name)

      # Add 3 entries (at capacity)
      CertificateCache.put(["cert1"], "key1", cache_name)
      :timer.sleep(10)
      CertificateCache.put(["cert2"], "key2", cache_name)
      :timer.sleep(10)
      CertificateCache.put(["cert3"], "key3", cache_name)
      :timer.sleep(10)

      # Verify all 3 are present
      assert {:ok, "key1"} = CertificateCache.get(["cert1"], cache_name)
      assert {:ok, "key2"} = CertificateCache.get(["cert2"], cache_name)
      assert {:ok, "key3"} = CertificateCache.get(["cert3"], cache_name)

      # Add a 4th entry - should evict the oldest (cert1)
      CertificateCache.put(["cert4"], "key4", cache_name)
      :timer.sleep(10)

      # cert1 should be evicted (oldest by expiration time)
      assert :miss == CertificateCache.get(["cert1"], cache_name)

      # Others should still be present
      assert {:ok, "key2"} = CertificateCache.get(["cert2"], cache_name)
      assert {:ok, "key3"} = CertificateCache.get(["cert3"], cache_name)
      assert {:ok, "key4"} = CertificateCache.get(["cert4"], cache_name)

      # Restore original max size
      if original_max_size do
        Application.put_env(
          :app_store_server_library,
          :certificate_cache_max_size,
          original_max_size
        )
      else
        Application.delete_env(:app_store_server_library, :certificate_cache_max_size)
      end
    end
  end

  describe "clear/1" do
    test "clears all entries from cache", %{cache: cache} do
      CertificateCache.put(["cert1"], "key1", cache)
      CertificateCache.put(["cert2"], "key2", cache)
      :timer.sleep(10)

      assert {:ok, "key1"} = CertificateCache.get(["cert1"], cache)

      CertificateCache.clear(cache)

      assert :miss == CertificateCache.get(["cert1"], cache)
      assert :miss == CertificateCache.get(["cert2"], cache)
    end
  end

  describe "stats/1" do
    test "returns current cache stats", %{cache: cache} do
      stats = CertificateCache.stats(cache)
      assert stats.size == 0
      assert stats.max_size == 32

      CertificateCache.put(["cert1"], "key1", cache)
      CertificateCache.put(["cert2"], "key2", cache)
      :timer.sleep(10)

      stats = CertificateCache.stats(cache)
      assert stats.size == 2
      assert stats.max_size == 32
    end
  end
end
