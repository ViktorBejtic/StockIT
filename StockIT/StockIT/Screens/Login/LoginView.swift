import SwiftUI

struct LoginView: View {
    @StateObject private var VM = LoginViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        LinearGradient(
                            colors: [Color.fiitPrimary, Color.fiitPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 200)
                            .offset(x: -100, y: -40)

                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 150)
                            .offset(x: 120, y: 30)

                        VStack(spacing: 16) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 110, height: 110)
                                        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                                )

                            VStack(spacing: 6) {
                                Text("StockIT")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("appTagline")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .padding(.top, 20)
                    }
                    .frame(height: geo.size.height * 0.38)
                    .clipShape(
                        UnevenRoundedRectangle(
                            bottomLeadingRadius: 36,
                            bottomTrailingRadius: 36
                        )
                    )

                    VStack(spacing: 24) {
                        Text("signInSubtitle")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("emailLabel")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundStyle(focusedField == .email ? .fiitPrimary : .secondary)
                                        .frame(width: 20)

                                    TextField("emailPlaceholder", text: $VM.email)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .focused($focusedField, equals: .email)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .email ? Color.fiitPrimary : .clear, lineWidth: 1.5)
                                )
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("passwordLabel")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(focusedField == .password ? .fiitPrimary : .secondary)
                                        .frame(width: 20)

                                    Group {
                                        if VM.showPassword {
                                            TextField("passwordLabel", text: $VM.password)
                                        } else {
                                            SecureField("passwordLabel", text: $VM.password)
                                        }
                                    }
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .password)

                                    Button {
                                        VM.showPassword.toggle()
                                    } label: {
                                        Image(systemName: VM.showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundStyle(.secondary)
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .password ? Color.fiitPrimary : .clear, lineWidth: 1.5)
                                )
                            }
                        }

                        Button {
                            focusedField = nil
                            VM.login()
                        } label: {
                            HStack(spacing: 8) {
                                if VM.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("signInButton")
                                        .font(.headline)

                                    Image(systemName: "arrow.right")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: VM.isSignInButtonDisabled
                                        ? [Color.gray.opacity(0.5), Color.gray.opacity(0.4)]
                                        : [Color.fiitPrimary, Color.fiitPrimary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(
                                color: VM.isSignInButtonDisabled ? .clear : Color.fiitPrimary.opacity(0.35),
                                radius: 8,
                                y: 4
                            )
                        }
                        .disabled(VM.isSignInButtonDisabled)
                        .animation(.easeInOut(duration: 0.2), value: VM.isSignInButtonDisabled)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 32)

                    Spacer(minLength: 40)
                }
                .frame(minHeight: geo.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(isPresented: $VM.isAuthenticated) {
            AppTabView()
        }
    }
}
