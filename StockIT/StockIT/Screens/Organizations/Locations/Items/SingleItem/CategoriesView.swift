
import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: SingleItemViewModel
    @Environment(\.dismiss) private var dismiss
    @State var selectedCategories: [ItemCategory]
    @State private var newCategoryName = ""
    @State private var categoryToDelete: ItemCategory? = nil
    @State private var categoryToEdit: ItemCategory? = nil

    var hasChanges: Bool {
        let originalIds = VM.selectedCategories.map { $0.id }.sorted()
        let newIds = selectedCategories.map { $0.id }.sorted()
        return originalIds != newIds
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formCard {
                        HStack {
                            sectionHeader(icon: "square.grid.2x2", title: "Available Categories")

                            Spacer()

                            if let mainUser = session.mainUser {
                                let canManageCategories = mainUser.permissionsFlatList.contains(where: {
                                    $0.permissionName == "EVERYTHING" || $0.permissionName == "MANAGE_CATEGORIES"
                                })

                                if canManageCategories {
                                    Button {
                                        newCategoryName = ""
                                        categoryToEdit = nil
                                        VM.showCreateUpdateCategory = true
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.fiitPrimary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if VM.availableCategories.isEmpty {
                            Text("noCategoriesAvailable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(VM.availableCategories.enumerated()), id: \.element.id) { index, category in
                                if index > 0 {
                                    Divider()
                                }

                                HStack {
                                    Image(systemName: selectedCategories.contains(where: { $0.id == category.id }) ? "checkmark.circle.fill" : "circle")
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
                                    if let idx = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                                        selectedCategories.remove(at: idx)
                                    } else {
                                        selectedCategories.append(category)
                                    }
                                }
                                .contextMenu {
                                    if let mainUser = session.mainUser {
                                        let canManageCategories = mainUser.permissionsFlatList.contains(where: {
                                            $0.permissionName == "EVERYTHING" || $0.permissionName == "MANAGE_CATEGORIES"
                                        })

                                        if canManageCategories {
                                            Button {
                                                categoryToEdit = category
                                                newCategoryName = category.name
                                                VM.showCreateUpdateCategory = true
                                            } label: {
                                                Label("editButton", systemImage: "pencil")
                                            }

                                            Button(role: .destructive) {
                                                categoryToDelete = category
                                            } label: {
                                                Label("deleteButton", systemImage: "trash")
                                            }
                                        }
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
            .alert("deleteCategoryConfirm", isPresented: Binding(get: {
                categoryToDelete != nil
            }, set: { newVal in
                if !newVal { categoryToDelete = nil }
            }), presenting: categoryToDelete) { category in
                Button("deleteButton", role: .destructive) {
                    VM.deleteCategory(categoryId: category.id)
                    selectedCategories.removeAll(where: { $0.id == category.id })
                }
                Button("cancelButton", role: .cancel) {}
            } message: { category in
                Text("\(category.name) will be permanently deleted.")
            }
            .sheet(isPresented: $VM.showCreateUpdateCategory) {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.subheadline)
                                        .foregroundStyle(.fiitPrimary)
                                    Text("categoryDetailsTitle")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.bottom, 4)

                                VM.labeledField("Name", text: $newCategoryName)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle(LocalizedStringKey(categoryToEdit == nil ? "newCategoryTitle" : "editCategoryTitle"))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("cancelButton") {
                                VM.showCreateUpdateCategory = false
                                newCategoryName = ""
                                categoryToEdit = nil
                            }
                            .foregroundStyle(.fiitPrimary)
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            let isDisabled = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                (categoryToEdit != nil && newCategoryName == categoryToEdit?.name)

                            Button(LocalizedStringKey(categoryToEdit == nil ? "createButton" : "updateButton")) {
                                if categoryToEdit == nil {
                                    VM.createCategory(name: newCategoryName)
                                } else {
                                    if let category = categoryToEdit {
                                        VM.updateCategory(name: newCategoryName, categoryId: category.id)

                                        if let updatedCategory = VM.availableCategories.first(where: { $0.id == category.id }),
                                           let selectedIndex = selectedCategories.firstIndex(where: { $0.id == category.id }) {
                                            selectedCategories[selectedIndex] = updatedCategory
                                        }
                                    }
                                }
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(isDisabled ? .gray : .fiitPrimary)
                            .disabled(isDisabled)
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .navigationTitle("categoriesTitle")
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
                        VM.selectedCategories = selectedCategories
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .fiitPrimary : .gray)
                    .disabled(!hasChanges)
                }
            }
            .refreshable {
                VM.getCategories(forceRefresh: true)
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
