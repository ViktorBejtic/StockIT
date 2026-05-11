
import SwiftUI

struct CategoriesFilterSheetView: View {
    @ObservedObject var VM: ItemsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategoryIDs: [Int] = []

    private var hasChanges: Bool {
        Set(selectedCategoryIDs) != Set(VM.filters.selectedCategoryIDs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formCard {
                        sectionHeader(icon: "square.grid.2x2", title: "categoriesTitle")

                        if VM.allCategories.isEmpty {
                            Text("noCategoriesAvailable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(VM.allCategories.enumerated()), id: \.element.id) { index, category in
                                if index > 0 {
                                    Divider()
                                }

                                HStack {
                                    Image(systemName: selectedCategoryIDs.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(.fiitPrimary)

                                    Text(category.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.forText)

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let index = selectedCategoryIDs.firstIndex(of: category.id) {
                                        selectedCategoryIDs.remove(at: index)
                                    } else {
                                        selectedCategoryIDs.append(category.id)
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
            .navigationTitle("selectCategoriesTitle")
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
                        VM.filters.selectedCategoryIDs = selectedCategoryIDs
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .fiitPrimary : .gray)
                    .disabled(!hasChanges)
                }
            }
            .onAppear {
                VM.getCategories()
                selectedCategoryIDs = VM.filters.selectedCategoryIDs
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
