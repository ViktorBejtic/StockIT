import SwiftUI

struct AccountChangePasswordView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: AccountViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "lock.fill", title: "changePasswordButton")

                    passwordField(
                        icon: "lock",
                        label: "Current Password",
                        text: $VM.currentPassword,
                        isVisible: $VM.isCurrentPasswordVisible
                    )

                    Divider().padding(.leading, 44)

                    passwordField(
                        icon: "lock.rotation",
                        label: "New Password",
                        text: $VM.newPassword,
                        isVisible: $VM.isNewPasswordVisible
                    )

                    Divider().padding(.leading, 44)

                    passwordField(
                        icon: "lock.badge.checkmark",
                        label: "Confirm Password",
                        text: $VM.confirmPassword,
                        isVisible: $VM.isConfirmPasswordVisible
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("passwordRequirementsTitle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)

                    ruleRow("10\u{2013}50 characters", fulfilled: VM.lengthValid)
                    ruleRow("Lowercase letter", fulfilled: VM.containsLowercase)
                    ruleRow("Uppercase letter", fulfilled: VM.containsUppercase)
                    ruleRow("Number", fulfilled: VM.containsDigit)
                    ruleRow("Special character", fulfilled: VM.containsSpecialChar)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                Button {
                    if let user = session.mainUser {
                        VM.changePassword(userID: user.userId)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.subheadline)
                        Text("updatePasswordButton")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(VM.isPasswordValid ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        VM.isPasswordValid ? Color.fiitPrimary : Color(.systemGray5),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .disabled(!VM.isPasswordValid)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("changePasswordButton")
        .onAppear {
            VM.currentPassword = ""
            VM.newPassword = ""
            VM.confirmPassword = ""
        }
    }


    @ViewBuilder
    private func passwordField(icon: String, label: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(label))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Group {
                        if isVisible.wrappedValue {
                            TextField(LocalizedStringKey(label), text: text)
                        } else {
                            SecureField(LocalizedStringKey(label), text: text)
                        }
                    }
                    .font(.subheadline)

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isVisible.wrappedValue.toggle()
                        }
                    } label: {
                        Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func ruleRow(_ text: String, fulfilled: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: fulfilled ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(fulfilled ? .green : .secondary)
            Text(LocalizedStringKey(text))
                .font(.caption)
                .foregroundStyle(fulfilled ? .forText : .secondary)
        }
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }
}
