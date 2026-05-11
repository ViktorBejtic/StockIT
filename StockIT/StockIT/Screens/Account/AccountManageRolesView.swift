import SwiftUI

struct AccountManageRolesView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: AccountViewModel

    @State private var expandedRoleNames: Set<String> = []
    @State private var shownRolePopover: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("allAvailableRolesSection")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    if VM.allRoles.isEmpty {
                        Text("noRolesAvailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(16)
                    } else {
                        ForEach(VM.allRoles.sorted(by: { $0.scopeType.scopeOrder < $1.scopeType.scopeOrder }), id: \.id) { role in
                            VStack(spacing: 0) {
                                Divider().padding(.leading, 16)

                                DisclosureGroup {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("permissionsLabel")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)
                                            .padding(.bottom, 2)

                                        ForEach(role.permissions, id: \.name) { perm in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(perm.name.humanized)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.forText)
                                                Text(perm.description)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                } label: {
                                    HStack {
                                        Button {
                                            if shownRolePopover == role.name {
                                                shownRolePopover = nil
                                            } else {
                                                shownRolePopover = nil
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                    shownRolePopover = role.name
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "info.circle")
                                                .foregroundStyle(.fiitPrimary)
                                        }
                                        .buttonStyle(.plain)
                                        .popover(
                                            isPresented: Binding(
                                                get: { shownRolePopover == role.name },
                                                set: { if !$0 { shownRolePopover = nil } }
                                            ),
                                            attachmentAnchor: .point(.trailing)
                                        ) {
                                            Text(role.description)
                                                .padding()
                                                .font(.caption)
                                                .multilineTextAlignment(.leading)
                                                .presentationCompactAdaptation(.popover)
                                        }

                                        Text(role.name.humanized)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.forText)

                                        Spacer()

                                        Text(role.scopeType.humanized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .tint(Color.fiitPrimary)
                                .contextMenu {
                                    Button {
                                        VM.roleToEdit = role
                                        VM.showCreateUpdateRoleSheet.toggle()
                                    } label: {
                                        Label("editButton", systemImage: "square.and.pencil")
                                    }
                                    Button(role: .destructive) {
                                        VM.contextMenuRoleName = role.name
                                        VM.showDeleteRoleAlert.toggle()
                                    } label: {
                                        Label("deleteButton", systemImage: "trash")
                                    }
                                }
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
        .navigationTitle("manageRolesTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    VM.roleToEdit = nil
                    VM.showCreateUpdateRoleSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.fiitPrimary)
                }
            }
        }
        .alert("deleteRoleButton", isPresented: $VM.showDeleteRoleAlert) {
            Button("deleteButton", role: .destructive) {
                if let roleName = VM.contextMenuRoleName {
                    VM.deleteRole(roleName: roleName)
                }
            }
            Button("cancelButton", role: .cancel) { }
        } message: {
            if let roleName = VM.contextMenuRoleName {
                Text("Are you sure you want to delete role \"\(roleName.humanized)\" ? This action cannot be undone.")
            } else {
                Text("deleteRoleConfirm")
            }
        }
        .sheet(isPresented: $VM.showCreateUpdateRoleSheet) {
            NavigationStack {
                CreateUpdateRoleView(VM: VM)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            VM.fetchData()
        }
        .refreshable {
            VM.fetchData()
        }
    }
}
