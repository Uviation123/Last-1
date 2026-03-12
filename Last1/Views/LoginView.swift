import SwiftUI
import AuthenticationServices

private enum AuthTab: Int {
    case signIn = 0, signUp = 1
}

struct LoginView: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme
    @State private var activeTab: AuthTab = .signIn
    @State private var previousTab: AuthTab = .signIn

    var body: some View {
        ZStack {
            Color.appBackground(colorScheme).ignoresSafeArea()

            if authVM.authMode == .verifyEmail {
                VerifyEmailScreen()
            } else {
                ScrollView {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 40)

                        // Logo + Branding
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.appSurfaceSecondary(colorScheme))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(Color.appAccent(colorScheme))
                            }

                            Text("Last 1%")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.appPrimaryText(colorScheme))

                            Text("Tiny gains. Massive results.")
                                .font(.subheadline)
                                .foregroundStyle(Color.appMutedText(colorScheme))
                        }

                        // Tab Switcher
                        TabSwitcher(activeTab: $activeTab, onTabChange: { newTab in
                            previousTab = activeTab
                            activeTab = newTab
                        })
                        .padding(.horizontal, 24)

                        // Form Card
                        VStack(spacing: 0) {
                            let movingRight = activeTab.rawValue > previousTab.rawValue
                            ZStack {
                                if activeTab == .signIn {
                                    SignInFormContent()
                                        .transition(
                                            .asymmetric(
                                                insertion: .move(edge: movingRight ? .trailing : .leading).combined(with: .opacity),
                                                removal:  .move(edge: movingRight ? .leading  : .trailing).combined(with: .opacity)
                                            )
                                        )
                                } else {
                                    SignUpFormContent()
                                        .transition(
                                            .asymmetric(
                                                insertion: .move(edge: movingRight ? .trailing : .leading).combined(with: .opacity),
                                                removal:  .move(edge: movingRight ? .leading  : .trailing).combined(with: .opacity)
                                            )
                                        )
                                }
                            }
                            .clipped()
                            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: activeTab)

                            if let error = authVM.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(Color.appDestructive)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 12)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.appSurface(colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color.appBorderDynamic(colorScheme), lineWidth: 1)
                                )
                                .shadow(
                                    color: colorScheme == .light ? .black.opacity(0.06) : .clear,
                                    radius: 8, y: 2
                                )
                        )
                        .padding(.horizontal, 20)

                        // Social Buttons + Footer
                        VStack(spacing: 16) {
                            OrDivider()

                            SocialButtonsRow()

                            TermsFooter()
                        }
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 24)
                    }
                }
            }
        }
    }
}

// MARK: - Tab Switcher

private struct TabSwitcher: View {
    @Binding var activeTab: AuthTab
    let onTabChange: (AuthTab) -> Void
    @Namespace private var tabNamespace
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach([AuthTab.signIn, AuthTab.signUp], id: \.rawValue) { tab in
                let label = tab == .signIn ? "Sign In" : "Sign Up"
                let isActive = activeTab == tab

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        onTabChange(tab)
                    }
                } label: {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isActive ? Color.appButtonLabel(colorScheme) : Color.appMutedText(colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if isActive {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appAccent(colorScheme))
                                    .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                            }
                        }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: activeTab)
            }
        }
        .padding(4)
        .background(Color.appSurfaceSecondary(colorScheme), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Sign In Form

private struct SignInFormContent: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: AuthInputField?
    @State private var showPassword = false

    var body: some View {
        @Bindable var authVM = authVM

        VStack(spacing: 16) {
            // Email
            LabeledField(label: "Email") {
                IconTextField(
                    icon: "envelope",
                    placeholder: "you@example.com",
                    text: $authVM.email,
                    focused: $focusedField,
                    field: .email
                )
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            }

            // Password with Forgot label row
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Password")
                        .font(.caption)
                        .foregroundStyle(Color.appMutedText(colorScheme))
                    Spacer()
                    Button("Forgot?") {}
                        .font(.caption)
                        .foregroundStyle(Color.appAccent(colorScheme))
                }

                PasswordField(
                    placeholder: "Enter your password",
                    text: $authVM.password,
                    showPassword: $showPassword,
                    focused: $focusedField,
                    field: .password
                )
                .textContentType(.password)
            }

            // Sign In Button
            Button {
                Task { await authVM.signIn() }
            } label: {
                HStack(spacing: 8) {
                    if authVM.isLoading {
                        ProgressView()
                            .tint(Color.appButtonLabel(colorScheme))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(Color.appButtonLabel(colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appAccent(colorScheme), in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(authVM.isLoading || authVM.email.isEmpty || authVM.password.isEmpty)
            .opacity((authVM.isLoading || authVM.email.isEmpty || authVM.password.isEmpty) ? 0.6 : 1)
        }
    }
}

// MARK: - Sign Up Form

private struct SignUpFormContent: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: AuthInputField?
    @State private var showPassword = false

    var body: some View {
        @Bindable var authVM = authVM

        VStack(spacing: 16) {
            // Full Name
            LabeledField(label: "Full Name") {
                IconTextField(
                    icon: "person",
                    placeholder: "Your name",
                    text: $authVM.fullName,
                    focused: $focusedField,
                    field: .name
                )
                .textContentType(.name)
                .autocorrectionDisabled()
            }

            // Email
            LabeledField(label: "Email") {
                IconTextField(
                    icon: "envelope",
                    placeholder: "you@example.com",
                    text: $authVM.email,
                    focused: $focusedField,
                    field: .email
                )
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            }

            // Password
            LabeledField(label: "Password") {
                PasswordField(
                    placeholder: "Enter your password",
                    text: $authVM.password,
                    showPassword: $showPassword,
                    focused: $focusedField,
                    field: .password
                )
                .textContentType(.newPassword)
            }

            // Create Account Button
            Button {
                Task { await authVM.register() }
            } label: {
                HStack(spacing: 8) {
                    if authVM.isLoading {
                        ProgressView()
                            .tint(Color.appButtonLabel(colorScheme))
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(Color.appButtonLabel(colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appAccent(colorScheme), in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(authVM.isLoading || authVM.email.isEmpty || authVM.password.isEmpty)
            .opacity((authVM.isLoading || authVM.email.isEmpty || authVM.password.isEmpty) ? 0.6 : 1)
        }
    }
}

// MARK: - Verify Email Screen

private struct VerifyEmailScreen: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var authVM = authVM

        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 80)

                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.appSurfaceSecondary(colorScheme))
                            .frame(width: 72, height: 72)
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(Color.appAccent(colorScheme))
                    }

                    Text("Check your email")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))

                    Text("We sent a verification code to\n\(authVM.email)")
                        .font(.subheadline)
                        .foregroundStyle(Color.appMutedText(colorScheme))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    TextField("8-digit code", text: $authVM.otpCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .focused($focused)
                        .font(.title2.monospaced())
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                        .padding()
                        .background(Color.appFieldBackground(colorScheme), in: RoundedRectangle(cornerRadius: 14))

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.appDestructive)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await authVM.verifyEmail() }
                    } label: {
                        HStack(spacing: 8) {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(Color.appButtonLabel(colorScheme))
                            } else {
                                Text("Verify Email")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundStyle(Color.appButtonLabel(colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.appAccent(colorScheme), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(authVM.isLoading || authVM.otpCode.isEmpty)
                    .opacity((authVM.isLoading || authVM.otpCode.isEmpty) ? 0.6 : 1)

                    Button("Use a different email") {
                        authVM.authMode = .register
                        authVM.otpCode = ""
                        authVM.resetError()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.appMutedText(colorScheme))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appSurface(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.appBorderDynamic(colorScheme), lineWidth: 1)
                        )
                        .shadow(
                            color: colorScheme == .light ? .black.opacity(0.06) : .clear,
                            radius: 8, y: 2
                        )
                )
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Social Buttons Row

private struct SocialButtonsRow: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Google
            Button {
                Task { await authVM.signInWithGoogle() }
            } label: {
                HStack(spacing: 8) {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text("Google")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appPrimaryText(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appSurfaceSecondary(colorScheme), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.appBorderDynamic(colorScheme), lineWidth: 1)
                )
            }
            .disabled(authVM.isLoading)

            // Apple — custom styled button with SignInWithAppleButton overlay
            AppleSignInButton()
        }
    }
}

private struct AppleSignInButton: View {
    @Environment(AuthViewModel.self) var authVM
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Visible custom style
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                Text("Apple")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.appSurfaceSecondary(colorScheme), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.appBorderDynamic(colorScheme), lineWidth: 1)
            )

            // Invisible Apple button on top for App Store compliance
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await authVM.handleAppleSignInCompletion(result) }
            }
            .blendMode(.destinationOver)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .disabled(authVM.isLoading)
    }
}

// MARK: - Or Divider

private struct OrDivider: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.appBorderDynamic(colorScheme))
                .frame(height: 1)
            Text("or")
                .font(.caption)
                .foregroundStyle(Color.appMutedText(colorScheme))
            Rectangle()
                .fill(Color.appBorderDynamic(colorScheme))
                .frame(height: 1)
        }
    }
}

// MARK: - Terms Footer

private struct TermsFooter: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        (Text("By continuing, you agree to our ")
         + Text("Terms").underline().foregroundColor(Color.appAccent(colorScheme))
         + Text(" and ")
         + Text("Privacy Policy").underline().foregroundColor(Color.appAccent(colorScheme)))
            .font(.caption)
            .foregroundStyle(Color.appMutedText(colorScheme))
            .multilineTextAlignment(.center)
    }
}

// MARK: - Reusable Field Components

private enum AuthInputField {
    case name, email, password
}

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.appMutedText(colorScheme))
            content()
        }
    }
}

private struct IconTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<AuthInputField?>.Binding
    let field: AuthInputField
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color.appMutedText(colorScheme))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundStyle(Color.appPrimaryText(colorScheme))
                .focused(focused, equals: field)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.appFieldBackground(colorScheme), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.appBorderDynamic(colorScheme).opacity(0.6), lineWidth: 1)
        )
    }
}

private struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var focused: FocusState<AuthInputField?>.Binding
    let field: AuthInputField
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 15))
                .foregroundStyle(Color.appMutedText(colorScheme))
                .frame(width: 20)

            if showPassword {
                TextField(placeholder, text: $text)
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                    .focused(focused, equals: field)
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(Color.appPrimaryText(colorScheme))
                    .focused(focused, equals: field)
            }

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appMutedText(colorScheme))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.appFieldBackground(colorScheme), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.appBorderDynamic(colorScheme).opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
