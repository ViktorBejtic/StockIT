
import SwiftUI

struct SearchStatusesFilterSheetView: View {
    @ObservedObject var VM: SearchViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStatuses: [ItemStatus] = []

    private var hasChanges: Bool {
        Set(selectedStatuses) != Set(VM.filters.selectedStatuses)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formCard {
                        sectionHeader(icon: "flag", title: "Statuses")

                        ForEach(Array(ItemStatus.allCases.enumerated()), id: \.element.id) { index, status in
                            if index > 0 {
                                Divider()
                            }

                            HStack {
                                Image(systemName: selectedStatuses.contains(status) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(.fiitPrimary)

                                Text(status.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.forText)

                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let index = selectedStatuses.firstIndex(of: status) {
                                    selectedStatuses.remove(at: index)
                                } else {
                                    selectedStatuses.append(status)
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
            .navigationTitle("selectStatusesTitle")
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
                        VM.filters.selectedStatuses = selectedStatuses
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .fiitPrimary : .gray)
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                selectedStatuses = VM.filters.selectedStatuses
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
