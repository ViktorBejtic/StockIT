import SwiftUI

struct CreateUpdateLocationView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: LocationsViewModel
    let organization: Organization
    var existingLocation: Location? = nil

    @State private var name: String = ""
    @State private var room: String = ""
    @State private var description: String = ""

    var isEditing: Bool {
        existingLocation != nil
    }

    var hasChanges: Bool {
        name != existingLocation?.name || room != existingLocation?.room || description != existingLocation?.description
    }

    var canSubmit: Bool {
        let allFilled = !name.isEmpty && !room.isEmpty && !description.isEmpty
        return isEditing ? allFilled && hasChanges : allFilled
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "mappin.and.ellipse", title: "Location Info")
                    styledField(icon: "textformat", label: "Name", placeholder: "Location name", text: $name)
                    Divider().padding(.leading, 44)
                    styledField(icon: "door.left.hand.open", label: "Room", placeholder: "Room number or name", text: $room)
                    Divider().padding(.leading, 44)
                    styledField(icon: "text.alignleft", label: "Description", placeholder: "What is this location for?", text: $description)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey(isEditing ? "editLocationTitle" : "newLocationTitle"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") {
                    VM.activeSheet = nil
                }
                .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey(isEditing ? "updateButton" : "createButton")) {
                    if isEditing {
                        if let locationId = existingLocation?.id {
                            VM.updateLocation(existingLocation: CreateUpdateLocationRequest(locationName: name, room: room, description: description, organizationId: organization.id), locationId: locationId)
                        }
                    } else {
                        VM.createLocation(newLocation: CreateUpdateLocationRequest(locationName: name, room: room, description: description, organizationId: organization.id))
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(canSubmit ? .fiitPrimary : .gray)
                .disabled(!canSubmit)
            }
        }
        .onAppear {
            if let loc = existingLocation {
                name = loc.name
                room = loc.room ?? ""
                description = loc.description
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
