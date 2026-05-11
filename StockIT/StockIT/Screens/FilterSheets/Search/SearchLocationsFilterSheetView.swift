
import SwiftUI

struct SearchLocationsFilterSheetView: View {
    @ObservedObject var VM: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLocationIDs: [Int] = []
    @State private var selectedOrganizationIDs: [Int] = []

    private var groupedLocations: [Int: [Location]] {
        Dictionary(grouping: VM.allLocations) { Int($0.organizationId) ?? 0 }
    }

    private var groupedOrganizationIDs: [Int] {
        groupedLocations.keys.sorted()
    }

    private func organizationName(for organizationId: Int) -> String {
        VM.allOrganizations.first(where: { $0.id == organizationId })?.name ?? "Unknown Organization"
    }

    private var hasChanges: Bool {
        Set(selectedLocationIDs) != Set(VM.filters.selectedLocationIDs) ||
        Set(selectedOrganizationIDs) != Set(VM.filters.selectedOrganizationIDs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(groupedOrganizationIDs, id: \.self) { orgID in
                        if let locations = groupedLocations[orgID], !locations.isEmpty {
                            formCard {
                                HStack(spacing: 8) {
                                    Image(systemName: VM.allLocationsSelected(for: orgID, selectedLocations: selectedLocationIDs) ? "checkmark.circle.fill" : "circle")
                                        .font(.subheadline)
                                        .foregroundStyle(.fiitPrimary)
                                        .onTapGesture {
                                            VM.toggleOrganizationSelection(
                                                orgID: orgID,
                                                selectedLocations: &selectedLocationIDs,
                                                selectedOrganizations: &selectedOrganizationIDs
                                            )
                                        }
                                    Text(organizationName(for: orgID))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.bottom, 4)

                                ForEach(Array(locations.enumerated()), id: \.element.id) { index, location in
                                    if index > 0 {
                                        Divider()
                                    }

                                    HStack {
                                        Image(systemName: selectedLocationIDs.contains(location.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(.fiitPrimary)

                                        Text(location.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.forText)

                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        VM.toggleLocationSelection(
                                            location,
                                            selectedLocations: &selectedLocationIDs,
                                            selectedOrganizations: &selectedOrganizationIDs
                                        )
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
            .navigationTitle("selectLocationsTitle")
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
                        VM.filters.selectedLocationIDs = selectedLocationIDs
                        VM.filters.selectedOrganizationIDs = selectedOrganizationIDs
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .fiitPrimary : .gray)
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                selectedLocationIDs = VM.filters.selectedLocationIDs
                selectedOrganizationIDs = VM.filters.selectedOrganizationIDs
                Task {
                    await VM.fetchStaticData()
                }
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
