
import SwiftUI

struct SelectLocationsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: GroupsViewModel
    @State var selectedLocations: [Location]
    let organization: Organization

    var hasChanges: Bool {
        let originalIds = VM.selectedLocations.map { $0.id }.sorted()
        let newIds = selectedLocations.map { $0.id }.sorted()
        return originalIds != newIds
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formCard {
                        sectionHeader(icon: "mappin.and.ellipse", title: "Available Locations")

                        if VM.allLocations.isEmpty {
                            Text("noLocationsAvailable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(VM.allLocations.enumerated()), id: \.element.id) { index, location in
                                let isSelected = selectedLocations.contains(where: { $0.id == location.id })

                                if index > 0 {
                                    Divider().padding(.leading, 58)
                                }

                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.fiitPrimary.opacity(0.12))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "mappin")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.fiitPrimary)
                                    }

                                    Text(location.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.forText)

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(.fiitPrimary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let idx = selectedLocations.firstIndex(where: { $0.id == location.id }) {
                                        selectedLocations.remove(at: idx)
                                    } else {
                                        selectedLocations.append(location)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("locationsTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancelButton") {
                        dismiss()
                    }
                    .foregroundStyle(.fiitPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("saveButton") {
                        VM.selectedLocations = selectedLocations
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .fiitPrimary : .gray)
                    .disabled(!hasChanges)
                }
            }
            .refreshable {
                VM.getLocations(organizationId: organization.id, forceRefresh: true)
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
}
