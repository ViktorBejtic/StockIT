
import SwiftUI

struct SearchAttributesFilterSheetView: View {
    @ObservedObject var VM: SearchViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAttributeIDs: [Int] = []
    @State private var expandedAttributeID: Int? = nil

    private var hasChanges: Bool {
        Set(selectedAttributeIDs) != Set(VM.filters.selectedAttributeIDs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formCard {
                        sectionHeader(icon: "tag", title: "attributesTitle")

                        if VM.allAttributes.isEmpty {
                            Text("noAttributesAvailable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(VM.allAttributes.enumerated()), id: \.element.id) { index, attribute in
                                if index > 0 {
                                    Divider()
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: selectedAttributeIDs.contains(attribute.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(.fiitPrimary)

                                        Text(attribute.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.forText)

                                        Spacer()

                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                expandedAttributeID = expandedAttributeID == attribute.id ? nil : attribute.id
                                            }
                                        } label: {
                                            Image(systemName: "info.circle")
                                                .foregroundStyle(Color.fiitPrimary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let idx = selectedAttributeIDs.firstIndex(of: attribute.id) {
                                            selectedAttributeIDs.remove(at: idx)
                                        } else {
                                            selectedAttributeIDs.append(attribute.id)
                                        }
                                    }

                                    if expandedAttributeID == attribute.id {
                                        Text(attribute.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.top, 2)
                                            .transition(.opacity)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("selectAttributesTitle")
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
                        VM.filters.selectedAttributeIDs = selectedAttributeIDs
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .fiitPrimary : .gray)
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                Task {
                    await VM.fetchStaticData()
                }
                selectedAttributeIDs = VM.filters.selectedAttributeIDs
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
