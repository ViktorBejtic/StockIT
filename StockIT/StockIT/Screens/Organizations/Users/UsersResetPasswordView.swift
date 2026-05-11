
import SwiftUI

struct UsersResetPasswordView: View {
    @ObservedObject var VM: UsersViewModel
    let userID: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formCard {
                        sectionHeader(icon: "lock.fill", title: "New Password")

                        HStack(spacing: 14) {
                            Image(systemName: "lock")
                                .font(.subheadline)
                                .foregroundStyle(.fiitPrimary)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 2) {
                                    Text("passwordLabel")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("*")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                }

                                HStack {
                                    if VM.showPassword {
                                        TextField("enterPasswordPlaceholder", text: $VM.newPassword)
                                            .textContentType(.newPassword)
                                            .font(.subheadline)
                                    } else {
                                        SecureField("enterPasswordPlaceholder", text: $VM.newPassword)
                                            .textContentType(.newPassword)
                                            .font(.subheadline)
                                    }

                                    Button {
                                        VM.showPassword.toggle()
                                    } label: {
                                        Image(systemName: VM.showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundStyle(.gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    formCard {
                        sectionHeader(icon: "checkmark.shield.fill", title: "passwordRequirementsTitle")

                        VStack(alignment: .leading, spacing: 8) {
                            passwordRuleRow("Password must be 10\u{2013}50 characters.", fulfilled: VM.lengthValid)
                            passwordRuleRow("Must contain a lowercase letter.", fulfilled: VM.containsLowercase)
                            passwordRuleRow("Must contain an uppercase letter.", fulfilled: VM.containsUppercase)
                            passwordRuleRow("Must contain a number.", fulfilled: VM.containsDigit)
                            passwordRuleRow("Must contain a special character.", fulfilled: VM.containsSpecialChar)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .presentationDetents([.medium])
            .navigationTitle("resetPasswordButton")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancelButton") {
                        VM.showResetPassword = false
                        VM.showUserDetailsResetPassword = false
                    }
                    .foregroundStyle(.fiitPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("resetButton") {
                        VM.resetPassword(userID: userID)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(VM.isPasswordValid ? .fiitPrimary : .gray)
                    .disabled(!VM.isPasswordValid)
                }
            }
        }
        .onAppear {
            VM.newPassword = ""
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

    private func passwordRuleRow(_ text: String, fulfilled: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: fulfilled ? "checkmark.circle.fill" : "circle")
                .font(.subheadline)
                .foregroundStyle(fulfilled ? .green : .secondary)
            Text(LocalizedStringKey(text))
                .font(.caption)
                .foregroundStyle(fulfilled ? .forText : .secondary)
        }
    }
}
