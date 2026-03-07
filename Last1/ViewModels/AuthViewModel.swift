import SwiftUI
import Supabase
import Observation
import AuthenticationServices
import CryptoKit
import GoogleSignIn

enum AuthMode {
    case landing, login, register, verifyEmail
}

@Observable
class AuthViewModel {
    var isAuthenticated = false
    var currentUserId: UUID?

    var authMode: AuthMode = .landing

    var fullName = ""
    var email = ""
    var password = ""
    var otpCode = ""
    var isLoading = false
    var errorMessage: String?

    private let authService = AuthService()

    init() {
        listenForAuthChanges()
    }

    private func listenForAuthChanges() {
        Task {
            for await (event, session) in SupabaseManager.client.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn:
                    isAuthenticated = session != nil
                    currentUserId = session?.user.id
                    if let sessionEmail = session?.user.email, !sessionEmail.isEmpty {
                        email = sessionEmail
                    }
                case .signedOut:
                    isAuthenticated = false
                    currentUserId = nil
                    email = ""
                default:
                    break
                }
            }
        }
    }

    func register() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(email: trimmedEmail, password: password)
            authMode = .verifyEmail
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func verifyEmail() async {
        guard !otpCode.isEmpty else {
            errorMessage = "Please enter the verification code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.verifySignUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                token: otpCode
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signIn() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(email: trimmedEmail, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign In

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple Sign In failed: could not read credentials."
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                try await authService.signInWithApple(idToken: idToken)
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false

        case .failure(let error):
            // ASAuthorizationError.canceled means the user dismissed the sheet — no error message needed.
            let asError = error as? ASAuthorizationError
            if asError?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        guard let rootViewController = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController
        else {
            errorMessage = "Unable to present Google Sign In."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let rawNonce = randomNonceString()
            let hashedNonce = sha256(rawNonce)

            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: [],
                nonce: hashedNonce
            )

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google Sign In failed: could not read ID token."
                isLoading = false
                return
            }

            try await authService.signInWithGoogle(idToken: idToken, nonce: rawNonce)
        } catch {
            // GIDSignInErrorCode.canceled means the user dismissed the sheet — no error shown.
            let gidError = error as? GIDSignInError
            if gidError?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Unable to generate nonce.")
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func resetToLanding() {
        authMode = .landing
        fullName = ""
        email = ""
        password = ""
        otpCode = ""
        errorMessage = nil
    }

    func resetError() {
        errorMessage = nil
    }

    #if DEBUG
    func skipAuth() {
        isAuthenticated = true
    }
    #endif
}
