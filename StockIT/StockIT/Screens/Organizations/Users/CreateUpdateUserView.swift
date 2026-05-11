import SwiftUI

struct CreateUpdateUserView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: UsersViewModel

    @Binding var existingUser: User?

    var isEditing: Bool {
        existingUser != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "person.fill", title: "personalInfoTitle")
                    styledField(icon: "person", label: "First Name", placeholder: "John", text: $VM.firstName)
                    Divider().padding(.leading, 44)
                    styledField(icon: "person", label: "Last Name", placeholder: "Doe", text: $VM.lastName)
                    Divider().padding(.leading, 44)
                    birthDateField
                    Divider().padding(.leading, 44)
                    phoneField
                }

                formCard {
                    sectionHeader(icon: "at", title: "Account Info")
                    styledField(icon: "envelope", label: "Email", placeholder: "user@example.com", text: $VM.email)

                    if !isEditing {
                        Divider().padding(.leading, 44)
                        passwordField
                    }
                }

                if !isEditing {
                    passwordRulesCard
                }

                formCard {
                    sectionHeader(icon: "house.fill", title: "addressLabel")
                    if !isEditing {
                        styledField(icon: "road.lanes", label: "Street", placeholder: "Street name", text: $VM.street)
                        Divider().padding(.leading, 44)
                        styledField(icon: "number", label: "Street Number", placeholder: "123", text: $VM.streetNumber)
                        Divider().padding(.leading, 44)
                        styledField(icon: "building", label: "City", placeholder: "City", text: $VM.city)
                        Divider().padding(.leading, 44)
                        styledField(icon: "envelope", label: "Postal Code", placeholder: "012 34", text: $VM.postalCode)
                        Divider().padding(.leading, 44)
                        styledField(icon: "globe", label: "Country", placeholder: "Country", text: $VM.country)
                    } else {
                        styledField(icon: "mappin", label: "Full Address", placeholder: "Full address", text: $VM.address)
                    }
                }

                formCard {
                    sectionHeader(icon: "text.quote", title: "Details")
                    styledField(icon: "text.alignleft", label: "Description", placeholder: "About this user", text: $VM.description)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey(isEditing ? "updateUserTitle" : "createUserTitle"))
        .navigationBarTitleDisplayMode(isEditing ? .inline : .large)
        .alert("passwordCopiedToClipboard", isPresented: $VM.showCopiedAlert) {
            Button("okButton", role: .cancel) { }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") {
                    VM.showEditUser = false
                    VM.showEditingUser = false
                    VM.showCreateUser = false
                }
                .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey(isEditing ? "updateButton" : "createButton")) {
                    if isEditing {
                        if existingUser != nil {
                            VM.updateUser(user: Binding(
                                get: { existingUser! },
                                set: { newValue in existingUser = newValue }
                            ))
                        }
                    } else {
                        VM.createUser()
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(submitEnabled ? .fiitPrimary : .gray)
                .disabled(!submitEnabled)
            }
        }
        .onAppear {
            if let user = existingUser {
                VM.fillForm(user: user)
            } else {
                VM.resetForm()
            }
        }
    }

    private var submitEnabled: Bool {
        isEditing ? infoChanged : VM.canSubmit
    }

    private var infoChanged: Bool {
        guard let user = existingUser else { return false }
        let hasChanges =
        user.firstName != VM.firstName ||
        user.lastName != VM.lastName ||
        user.email != VM.email ||
        user.phoneNumber != VM.phoneNumber ||
        user.birthDate != VM.birthDateFormatted ||
        user.address != VM.address ||
        user.description != VM.description

        let isNotEmpty = !VM.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.description.trimmingCharacters(in: .whitespaces).isEmpty &&
        VM.isValidDate

        return hasChanges && isNotEmpty
    }


    private var birthDateField: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text("birthDateLabel")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("DD/MM/YYYY", text: $VM.birthDateString)
                        .keyboardType(.numberPad)
                        .font(.subheadline)
                        .foregroundStyle(VM.isValidDate ? .forText : .red)
                        .onChange(of: VM.birthDateString) {
                            VM.formatInput()
                        }

                    Spacer()

                    DatePicker("", selection: $VM.birthDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .onChange(of: VM.birthDate) {
                            VM.birthDateString = VM.dateFormatter.string(from: VM.birthDate)
                            VM.isValidDate = true
                        }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            VM.birthDateString = VM.dateFormatter.string(from: VM.birthDate)
        }
    }


    private var phoneField: some View {
        HStack(spacing: 14) {
            Image(systemName: "phone.fill")
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text("phoneNumberLabel")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    if !isEditing {
                        Text("+")
                            .foregroundStyle(.forText)
                            .font(.subheadline)
                        TextField("421", text: $VM.phonePrefix)
                            .keyboardType(.numberPad)
                            .frame(width: 30)
                            .font(.subheadline)
                        Divider().frame(height: 18)
                    }
                    TextField("123 456 789", text: $VM.phoneNumber)
                        .keyboardType(.numberPad)
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }


    private var passwordField: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("passwordLabel")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("generateButton") {
                        withAnimation(.spring()) {
                            VM.newPassword = VM.generatePassword()
                        }
                    }
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5), in: Capsule())

                    Button("copyButton") {
                        UIPasteboard.general.string = VM.newPassword
                        VM.showCopiedAlert = true
                    }
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VM.newPassword.isEmpty ? Color(.systemGray6) : Color(.systemGray5), in: Capsule())
                    .disabled(VM.newPassword.isEmpty)
                }

                HStack {
                    Group {
                        if VM.showPassword {
                            TextField("passwordLabel", text: $VM.newPassword)
                        } else {
                            SecureField("passwordLabel", text: $VM.newPassword)
                        }
                    }
                    .font(.subheadline)

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            VM.showPassword.toggle()
                        }
                    } label: {
                        Image(systemName: VM.showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }


    private var passwordRulesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            ruleRow("10–50 characters", fulfilled: VM.lengthValid)
            ruleRow("Lowercase letter", fulfilled: VM.containsLowercase)
            ruleRow("Uppercase letter", fulfilled: VM.containsUppercase)
            ruleRow("Number", fulfilled: VM.containsDigit)
            ruleRow("Special character", fulfilled: VM.containsSpecialChar)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
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

    private func styledField(icon: String, label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(label))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(LocalizedStringKey(placeholder), text: text)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}
