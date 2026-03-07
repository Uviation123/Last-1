import StoreKit

// MARK: - Store Error

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed. Please try again."
        case .productNotFound:
            return "Subscription product not found. Please check your connection and try again."
        }
    }
}

// MARK: - SubscriptionService

/// Pure StoreKit 2 interface. All methods are stateless; state lives in SubscriptionViewModel.
struct SubscriptionService {

    /// Must match the Auto-Renewable Subscription product ID in App Store Connect.
    static let productID = "com.last1.pro.monthly"

    // MARK: Product Fetching

    func fetchProduct() async throws -> Product? {
        let products = try await Product.products(for: [Self.productID])
        return products.first
    }

    // MARK: Purchase

    /// Initiates the StoreKit purchase sheet. Returns the verified Transaction on success,
    /// or nil if the user cancelled or the purchase is pending (e.g. Ask to Buy).
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    // MARK: Entitlement Check

    /// Returns true if the user currently has an active, unrevoked subscription.
    var isSubscribed: Bool {
        get async {
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result,
                   transaction.productID == Self.productID,
                   transaction.revocationDate == nil {
                    return true
                }
            }
            return false
        }
    }

    // MARK: Restore

    /// Syncs the latest transactions from Apple. After calling this, re-check isSubscribed.
    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    // MARK: Verification Helper

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let payload):
            return payload
        }
    }
}
