import Foundation
import Supabase

struct AuthService {
    private var client: SupabaseClient { SupabaseManager.client }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func verifySignUp(email: String, token: String) async throws {
        try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .signup
        )
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func session() async throws -> Session {
        try await client.auth.session
    }

    func signInWithApple(idToken: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken)
        )
    }

    func signInWithGoogle(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, nonce: nonce)
        )
    }
}
