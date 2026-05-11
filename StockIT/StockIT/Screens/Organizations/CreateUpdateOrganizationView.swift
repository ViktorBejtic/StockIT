import SwiftUI

struct CreateUpdateOrganizationView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: OrganizationsViewModel
    var existingOrganization: Organization? = nil

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var street: String = ""
    @State private var streetNumber: String = ""
    @State private var city: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = ""

    var isEditing: Bool {
        existingOrganization != nil
    }

    var hasChanges: Bool {
        name != existingOrganization?.name ||
        description != existingOrganization?.description ||
        street != existingOrganization?.street ||
        streetNumber != existingOrganization?.streetNumber ||
        city != existingOrganization?.city ||
        postalCode != existingOrganization?.postalCode ||
        country != existingOrganization?.country
    }

    var canSubmit: Bool {
        let allFilled = !name.isEmpty && !description.isEmpty && !street.isEmpty && !streetNumber.isEmpty && !city.isEmpty && !postalCode.isEmpty && !country.isEmpty
        return isEditing ? allFilled && hasChanges : allFilled
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "building.2.fill", title: "Organization Details")
                    styledField(icon: "textformat", label: "Name", placeholder: "Organization name", text: $name)
                    Divider().padding(.leading, 44)
                    styledField(icon: "text.alignleft", label: "Description", placeholder: "What does this org do?", text: $description)
                }

                formCard {
                    sectionHeader(icon: "mappin.and.ellipse", title: "addressLabel")
                    styledField(icon: "road.lanes", label: "Street", placeholder: "Street name", text: $street)
                    Divider().padding(.leading, 44)
                    styledField(icon: "number", label: "Street Number", placeholder: "123", text: $streetNumber)
                    Divider().padding(.leading, 44)
                    styledField(icon: "building", label: "City", placeholder: "City", text: $city)
                    Divider().padding(.leading, 44)
                    styledField(icon: "envelope", label: "Postal Code", placeholder: "012 34", text: $postalCode)
                    Divider().padding(.leading, 44)
                    styledField(icon: "globe", label: "Country", placeholder: "Country", text: $country)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey(isEditing ? "editOrganizationTitle" : "newOrganizationTitle"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") {
                    VM.activeSheet = nil
                }
                .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey(isEditing ? "updateButton" : "createButton")) {
                    let orgRequest = CreateUpdateOrganizationRequest(
                        name: name,
                        description: description,
                        street: street,
                        streetNumber: streetNumber,
                        city: city,
                        postalCode: postalCode,
                        country: country
                    )
                    if isEditing {
                        if let id = existingOrganization?.id {
                            VM.updateOrganization(existingOrganization: orgRequest, organizationId: id)
                        }
                    } else {
                        VM.createOrganization(newOrganization: orgRequest)
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(canSubmit ? .fiitPrimary : .gray)
                .disabled(!canSubmit)
            }
        }
        .onAppear {
            if let org = existingOrganization {
                name = org.name
                description = org.description
                street = org.street
                streetNumber = org.streetNumber
                city = org.city
                postalCode = org.postalCode
                country = org.country
            }
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
