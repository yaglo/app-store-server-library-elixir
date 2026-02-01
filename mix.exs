defmodule AppStoreServerLibrary.MixProject do
  use Mix.Project

  @version "2.2.0"
  @source_url "https://github.com/yaglo/app-store-server-library-elixir"

  def project do
    [
      app: :app_store_server_library,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "AppStoreServerLibrary",
      source_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto, :public_key],
      mod: {AppStoreServerLibrary.Application, []}
    ]
  end

  defp description do
    "Elixir client for Apple App Store Server API, Server Notifications, and Retention Messaging."
  end

  defp package do
    [
      name: "app_store_server_library",
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        "API Client": [
          AppStoreServerLibrary.API.AppStoreServerAPIClient,
          AppStoreServerLibrary.API.APIException,
          AppStoreServerLibrary.API.APIError
        ],
        Verification: [
          AppStoreServerLibrary.Verification.SignedDataVerifier,
          AppStoreServerLibrary.Verification.ChainVerifier
        ],
        Signatures: [
          AppStoreServerLibrary.Signature.JWSSignatureCreator,
          AppStoreServerLibrary.Signature.PromotionalOfferSignatureCreator,
          AppStoreServerLibrary.Signature.PromotionalOfferV2SignatureCreator,
          AppStoreServerLibrary.Signature.IntroductoryOfferEligibilitySignatureCreator,
          AppStoreServerLibrary.Signature.AdvancedCommerceAPIInAppSignatureCreator,
          AppStoreServerLibrary.Signature.AdvancedCommerceAPIInAppRequest
        ],
        Utilities: [
          AppStoreServerLibrary.Utility.ReceiptUtility
        ],
        "OTP Application": [
          AppStoreServerLibrary.Application,
          AppStoreServerLibrary.Cache.CertificateCache,
          AppStoreServerLibrary.Cache.TokenCache
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # JWT/JWS signing and verification
      {:jose, "~> 1.11"},
      # HTTP client
      {:req, "~> 0.5"},
      # JSON encoding/decoding
      {:jason, "~> 1.4"},
      # UUID generation
      {:uuid, "~> 1.1"},
      # X.509 certificate handling (for chain verification)
      {:x509, "~> 0.9"},
      # HTTP mocking for tests
      {:bypass, "~> 2.1", only: :test},
      # Documentation generation
      {:ex_doc, "~> 0.39", only: :dev, runtime: false},
      # Code analysis
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # Static type checking
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
