
import SwiftUI

struct AccountPersonalInformationView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: AccountViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if VM.isEditing {
                    editPersonalInfoCard
                } else {
                    viewPersonalInfoCard
                }

                if VM.isEditing {
                    editAddressCard
                } else {
                    viewAddressCard
                }

                if VM.isEditing {
                    editDescriptionCard
                } else {
                    viewDescriptionCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("personalInfoTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if VM.isEditing {
                    Button("cancelButton") {
                        if let user = session.mainUser {
                            VM.loadData(from: user)
                        }
                        VM.isEditing = false
                    }
                    .foregroundStyle(.fiitPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if VM.isEditing {
                    Button("saveButton") {
                        if let user = session.mainUser {
                            VM.updateUser(userID: user.userId)
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(infoChanged ? .fiitPrimary : .gray)
                    .disabled(!infoChanged)
                } else {
                    Button("editButton") {
                        VM.isEditing = true
                    }
                    .foregroundStyle(.fiitPrimary)
                }
            }
        }
        .onAppear {
            if let user = session.mainUser {
                VM.loadData(from: user)
            }
        }
    }


    private var viewPersonalInfoCard: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "person.fill", title: "Personal Information")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            infoRow(icon: "person", label: "First Name", value: VM.firstName)
            Divider().padding(.leading, 52)
            infoRow(icon: "person", label: "Last Name", value: VM.lastName)
            Divider().padding(.leading, 52)
            infoRow(icon: "envelope", label: "Email", value: VM.email)
            Divider().padding(.leading, 52)
            infoRow(icon: "phone.fill", label: "Phone", value: VM.phone)
            Divider().padding(.leading, 52)
            infoRow(icon: "calendar", label: "Birth Date", value: VM.birthDateString)
        }
        .padding(.bottom, 8)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var viewAddressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "house.fill", title: "addressLabel")
            Text(VM.address.isEmpty ? "-" : VM.address)
                .font(.subheadline)
                .foregroundStyle(.forText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var viewDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "text.quote", title: "descriptionLabel")
            Text(VM.description.isEmpty ? "-" : VM.description)
                .font(.subheadline)
                .foregroundStyle(.forText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var editPersonalInfoCard: some View {
        formCard {
            sectionHeader(icon: "person.fill", title: "Personal Information")
            styledField(icon: "person", label: "First Name", placeholder: "First Name", text: $VM.firstName)
            Divider().padding(.leading, 44)
            styledField(icon: "person", label: "Last Name", placeholder: "Last Name", text: $VM.lastName)
            Divider().padding(.leading, 44)
            styledField(icon: "envelope", label: "Email", placeholder: "Email", text: $VM.email)
            Divider().padding(.leading, 44)
            styledField(icon: "phone.fill", label: "Phone", placeholder: "Phone", text: $VM.phone)
            Divider().padding(.leading, 44)
            birthDateField
        }
    }

    private var editAddressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "house.fill", title: "addressLabel")
            TextField(LocalizedStringKey("addressLabel"), text: $VM.address)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var editDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "text.quote", title: "descriptionLabel")
            TextField(LocalizedStringKey("descriptionLabel"), text: $VM.description)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
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
            VM.formatInput()
        }
    }


    private var infoChanged: Bool {
        guard let user = session.mainUser else { return false }

        let hasChanges =
        user.firstName != VM.firstName ||
        user.lastName != VM.lastName ||
        user.email != VM.email ||
        user.phoneNumber != VM.phone ||
        user.birthDate != VM.birthDateFormatted ||
        user.address != VM.address ||
        user.description != VM.description

        let isNotEmpty = !VM.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !VM.description.trimmingCharacters(in: .whitespaces).isEmpty &&
        VM.isValidDate

        return hasChanges && isNotEmpty
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(label))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline)
                    .foregroundStyle(.forText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
