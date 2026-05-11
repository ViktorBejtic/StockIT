
import SwiftUI

struct AttributesView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: SingleItemViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateAttribute = false
    @State private var newAttributeName = ""
    @State private var newAttributeDescription = ""
    @State private var attributeToEdit: Attribute? = nil
    @State private var attributeToDelete: Attribute? = nil
    @State private var showDescriptionId: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "tag", title: "Available Attributes")

                    if VM.availableAttributes.isEmpty {
                        Text("noAttributesAvailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(VM.availableAttributes.enumerated()), id: \.element.id) { index, attribute in
                            if index > 0 {
                                Divider()
                            }

                            VStack(alignment: .leading) {
                                HStack {
                                    Text(attribute.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.forText)

                                    Spacer()

                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if showDescriptionId == nil {
                                                showDescriptionId = attribute.id
                                            } else {
                                                showDescriptionId = nil
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .foregroundStyle(Color.fiitPrimary)
                                    }
                                    .buttonStyle(.plain)
                                }

                                if showDescriptionId == attribute.id {
                                    Text(attribute.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 2)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                VM.selectedAttributes.append(SelectedAttribute(attribute: attribute, value: ""))
                                dismiss()
                            }
                            .contextMenu {
                                if let mainUser = session.mainUser {
                                    let canManageAttributes = mainUser.permissionsFlatList.contains(where: {
                                        $0.permissionName == "EVERYTHING" || $0.permissionName == "MANAGE_ATTRIBUTES"
                                    })

                                    if canManageAttributes {
                                        Button {
                                            attributeToEdit = attribute
                                            newAttributeName = attribute.name
                                            newAttributeDescription = attribute.description
                                            showCreateAttribute = true
                                        } label: {
                                            Label("editButton", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            attributeToDelete = attribute
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
        .alert("deleteAttributeConfirm", isPresented: Binding(get: {
            attributeToDelete != nil
        }, set: { newVal in
            if !newVal { attributeToDelete = nil }
        }), presenting: attributeToDelete) { attribute in
            Button("deleteButton", role: .destructive) {
                VM.deleteAttribute(attributeId: attribute.id)
            }
            Button("cancelButton", role: .cancel) { }
        } message: { attribute in
            Text("\(attribute.name) will be permanently deleted.")
        }
        .sheet(isPresented: $showCreateAttribute) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(.fiitPrimary)
                                Text("attributeDetailsTitle")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.bottom, 4)

                            VM.labeledField("Name", text: $newAttributeName)
                            VM.labeledField("Description", text: $newAttributeDescription)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(LocalizedStringKey(attributeToEdit == nil ? "newAttributeTitle" : "editAttributeTitle"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancelButton") {
                            showCreateAttribute = false
                            newAttributeName = ""
                            newAttributeDescription = ""
                            attributeToEdit = nil
                        }
                        .foregroundStyle(.fiitPrimary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        let isDisabled = newAttributeName.trimmingCharacters(in: .whitespaces).isEmpty ||
                            newAttributeDescription.trimmingCharacters(in: .whitespaces).isEmpty ||
                            (attributeToEdit != nil && newAttributeName == attributeToEdit?.name && newAttributeDescription == attributeToEdit?.description)

                        Button(LocalizedStringKey(attributeToEdit == nil ? "createButton" : "updateButton")) {
                            if let attr = attributeToEdit {
                                VM.updateAttribute(name: newAttributeName, description: newAttributeDescription, attributeId: attr.id)
                            } else {
                                VM.createAttribute(name: newAttributeName, description: newAttributeDescription)
                            }
                            showCreateAttribute = false
                            newAttributeName = ""
                            newAttributeDescription = ""
                            attributeToEdit = nil
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(isDisabled ? .gray : .fiitPrimary)
                        .disabled(isDisabled)
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .navigationTitle("attributesTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") {
                    dismiss()
                }
                .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                if let mainUser = session.mainUser {
                    let canManageAttributes = mainUser.permissionsFlatList.contains(where: {
                        $0.permissionName == "EVERYTHING" || $0.permissionName == "MANAGE_ATTRIBUTES"
                    })

                    if canManageAttributes {
                        Button {
                            newAttributeName = ""
                            newAttributeDescription = ""
                            attributeToEdit = nil
                            showCreateAttribute = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.fiitPrimary)
                        }
                    }
                }
            }
        }
        .refreshable {
            VM.getAttributes(forceRefresh: true)
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
