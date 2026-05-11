
import SwiftUI

struct SearchOrganizationsFilterSheetView: View {
    @ObservedObject var VM: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOrganizationIDs: [Int] = []
    @State private var selectedLocationIDs: [Int] = []

    private var hasChanges: Bool {
        Set(selectedOrganizationIDs) != Set(VM.filters.selectedOrganizationIDs) ||
        Set(selectedLocationIDs) != Set(VM.filters.selectedLocationIDs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formCard {
                        sectionHeader(icon: "building.2", title: "organizationsTitle")

                        if VM.allOrganizations.isEmpty {
                            Text("noOrganizationsAvailable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(VM.allOrganizations.enumerated()), id: \.element.id) { index, organization in
                                if index > 0 {
                                    Divider()
                                }

                                HStack {
                                    Image(systemName: selectedOrganizationIDs.contains(organization.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(.fiitPrimary)

                                    Text(organization.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.forText)

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    VM.toggleOrganization(
                                        id: organization.id,
                                        selectedOrganizations: &selectedOrganizationIDs,
                                        selectedLocations: &selectedLocationIDs
                                    )
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
            .navigationTitle("selectOrganizationsTitle")
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
                        VM.filters.selectedOrganizationIDs = selectedOrganizationIDs
                        VM.filters.selectedLocationIDs = selectedLocationIDs
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .fiitPrimary : .gray)
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                selectedOrganizationIDs = VM.filters.selectedOrganizationIDs
                selectedLocationIDs = VM.filters.selectedLocationIDs
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
