
import SwiftUI

struct CreateUpdateRoleView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: AccountViewModel

    var isEditMode: Bool {
        VM.roleToEdit != nil
    }

    let allScopes: [String] = ["ORGANIZATION", "GROUP", "LOCATION", "GLOBAL"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "tag.fill", title: "Role Info")

                    styledField(icon: "pencil", label: "Role Name", placeholder: "Enter role name", text: $VM.roleName)
                    Divider().padding(.leading, 44)
                    styledField(icon: "text.alignleft", label: "Description", placeholder: "Enter description", text: $VM.roleDescription)
                    Divider().padding(.leading, 44)

                    HStack(spacing: 14) {
                        Image(systemName: "scope")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("scopeLabel")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("scopeLabel", selection: $VM.roleScopeType) {
                                ForEach(allScopes, id: \.self) { scope in
                                    Text(LocalizedStringKey(scope.capitalized)).tag(scope)
                                }
                            }
                            .labelsHidden()
                            .tint(.fiitPrimary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("permissionsLabel")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("(\(VM.filteredPermissions.count))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    if VM.filteredPermissions.isEmpty {
                        Text("noPermissionsForScope")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    } else {
                        ForEach(VM.filteredPermissions, id: \.name) { permission in
                            VStack(spacing: 0) {
                                Divider().padding(.leading, 16)

                                Button {
                                    if VM.selectedPermissions.contains(permission.name) {
                                        VM.selectedPermissions.remove(permission.name)
                                    } else {
                                        VM.selectedPermissions.insert(permission.name)
                                    }
                                } label: {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: VM.selectedPermissions.contains(permission.name) ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(VM.selectedPermissions.contains(permission.name) ? .fiitPrimary : .secondary)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(permission.name.humanized)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.forText)
                                            Text(permission.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey(isEditMode ? "editRoleTitle" : "createRoleTitle"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") {
                    VM.showCreateUpdateRoleSheet = false
                }
                .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey(isEditMode ? "updateButton" : "createButton")) {
                    if isEditMode {
                        if let roleToEdit = VM.roleToEdit {
                            VM.updateRole(roleToEditName: roleToEdit.name)
                        }
                    } else {
                        VM.createRole()
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(submitEnabled ? .fiitPrimary : .gray)
                .disabled(!submitEnabled)
            }
        }
        .onAppear {
            VM.fetchData()
            if let role = VM.roleToEdit {
                VM.roleName = role.name
                VM.roleDescription = role.description
                VM.roleScopeType = role.scopeType
                VM.selectedPermissions = Set(role.permissions.compactMap { $0.name })
            } else {
                VM.roleName = ""
                VM.roleDescription = ""
                VM.roleScopeType = "GLOBAL"
                VM.selectedPermissions = []
                VM.selectedPermissions.insert("VIEW_ATTRIBUTES")
                VM.selectedPermissions.insert("VIEW_CATEGORIES")
            }
        }
    }

    private var submitEnabled: Bool {
        isEditMode ? VM.canSubmitEditRole : VM.canSubmitRole
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
