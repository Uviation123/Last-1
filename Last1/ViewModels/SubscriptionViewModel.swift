import StoreKit
import Observation

// MARK: - SubscriptionViewModel

/// @Observable manager for subscription state. Create once in Last1App and inject via environment.
/// The transaction listener task runs for the full app lifetime, catching deferred and
/// interrupted purchases (e.g. Ask to Buy approvals, billing issue recoveries).
@Observable
@MainActor
final class SubscriptionViewModel {

    // MARK: Published State

    var isSubscribed = false
    var isLoading = false
    var errorMessage: String?
    var product: Product?

    // MARK: Private

    private let service = SubscriptionService()
    nonisolated(unsafe) private var listenerTask: Task<Void, Never>?

    // MARK: Init / Deinit

    init() {
        listenerTask = startTransactionListener()
        Task { await loadInitialState() }
    }

    deinit {
        listenerTask?.cancel()
    }

    // MARK: Public API

    /// Fetches the subscription product and checks current entitlements.
    func loadInitialState() async {
        async let productFetch: Product? = {
            try? await service.fetchProduct()
        }()
        async let subscribed: Bool = service.isSubscribed

        product = await productFetch
        isSubscribed = await subscribed
    }

    /// Explicitly re-fetches the subscription product. Call from the paywall onAppear
    /// to ensure the product is available before the user taps "Start Free Trial".
    func loadProduct() async {
        guard product == nil else { return }
        do {
            product = try await service.fetchProduct()
        } catch {
            print("[SubscriptionViewModel] loadProduct failed: \(error)")
        }
    }

    /// Initiates the StoreKit purchase sheet for the free trial.
    /// Returns true when the purchase completes successfully, false on cancellation or error.
    @discardableResult
    func startFreeTrial() async -> Bool {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        // Re-fetch the product if it wasn't loaded yet
        if product == nil {
            do {
                product = try await service.fetchProduct()
            } catch {
                print("[SubscriptionViewModel] startFreeTrial product fetch failed: \(error)")
                errorMessage = "Could not load subscription details: \(error.localizedDescription)"
                return false
            }
        }

        guard let product else {
            errorMessage = "Could not load subscription details. Check that the product ID is correct in App Store Connect."
            return false
        }

        do {
            let transaction = try await service.purchase(product)
            if transaction != nil {
                isSubscribed = true
                return true
            }
            // nil means user cancelled or purchase is pending
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Re-syncs with App Store and refreshes subscription status.
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.restorePurchases()
            isSubscribed = await service.isSubscribed
            if !isSubscribed {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Transaction Listener

    /// Listens for transaction updates pushed by StoreKit (renewals, revocations, Ask to Buy).
    private func startTransactionListener() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                do {
                    let transaction = try self.service.checkVerified(result)
                    await MainActor.run {
                        if transaction.revocationDate == nil {
                            self.isSubscribed = true
                        } else {
                            self.isSubscribed = false
                        }
                    }
                    await transaction.finish()
                } catch {
                    // Unverified transaction — ignore
                }
            }
        }
    }
}
