import SwiftUI

struct UsersView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM = UsersViewModel()

    var organizationId: String? = nil

    var body: some View {
        Group {
            if VM.filteredUsers.isEmpty && !VM.searchText.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 60)
                        Text("No users match \"\(VM.searchText)\"")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(VM.filteredUsers) { user in
                            if let index = VM.users.firstIndex(where: { $0.id == user.id }) {
                                NavigationLink {
                                    UserDetailView(VM: VM, user: $VM.users[index])
                                } label: {
                                    userCell(user: user)
                                }
                                .contextMenu {
                                    userContextMenu(user: user, index: index)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .searchable(text: $VM.searchText)
        .navigationTitle("usersTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    VM.showCreateUser = true
                } label: {
                    Image(systemName: "plus")
                        .tint(Color.fiitPrimary)
                }
            }
        }
        .sheet(isPresented: $VM.showResetPassword) {
            if let index = VM.contextMenuUserIndex {
                UsersResetPasswordView(VM: VM, userID: VM.users[index].userId)
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $VM.showCreateUser) {
            NavigationStack {
                CreateUpdateUserView(VM: VM, existingUser: .constant(nil))
            }
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $VM.showEditUser) {
            if let index = VM.contextMenuUserIndex {
                NavigationStack {
                    CreateUpdateUserView(
                        VM: VM,
                        existingUser: Binding<User?>(
                            get: { VM.users[index] },
                            set: { newValue in
                                if let updated = newValue {
                                    VM.users[index] = updated
                                }
                            }
                        )
                    )
                    .navigationBarBackButtonHidden()
                    .tint(Color.fiitPrimary)
                }
            }
        }
        .alert(VM.alertType?.alertTitle ?? "confirmActionTitle".localized, isPresented: $VM.showAlert) {
            Button(VM.alertType?.buttonLabel ?? "confirmButton".localized, role: .destructive) {
                switch VM.alertType {
                case .deleteUser:
                    if let index = VM.contextMenuUserIndex {
                        VM.deleteUser(userID: VM.users[index].userId)
                    }
                case .disableUser:
                    if let index = VM.contextMenuUserIndex {
                        VM.disableUser(user: $VM.users[index])
                    }
                case .enableUser:
                    if let index = VM.contextMenuUserIndex {
                        VM.enableUser(user: $VM.users[index])
                    }
                case .none:
                    break
                }
            }
            Button("cancelButton", role: .cancel) { }
        } message: {
            Text(VM.alertMessage)
        }
        .onAppear {
            VM.organizationFilter = organizationId
            VM.getUsers()
        }
        .refreshable {
            VM.getUsers(forceRefresh: true)
        }
    }


    private func userCell(user: User) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        user.accountActive == "false"
                            ? Color.red.opacity(0.12)
                            : Color.fiitPrimary.opacity(0.12)
                    )
                    .frame(width: 44, height: 44)

                Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)).uppercased())
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(user.accountActive == "false" ? .red : .fiitPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.forText)

                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if user.accountActive == "false" {
                Text("disabledLabel")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.1), in: Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.forText)
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }


    @ViewBuilder
    private func userContextMenu(user: User, index: Int) -> some View {
        if let mainUser = session.mainUser {
            let isSuperAdmin = mainUser.permissionsFlatList.contains { $0.permissionName == "EVERYTHING" }

            let canManageOrgUser: Bool = {
                guard let targetScopeId = user.permissionsFlatList.first(where: {
                    $0.permissionName == "VIEW_ORGANIZATION" &&
                    $0.scopeType == "ORGANIZATION"
                })?.scopeId else {
                    return false
                }
                return mainUser.permissionsFlatList.contains {
                    $0.permissionName == "MANAGE_USERS" &&
                    $0.scopeType == "ORGANIZATION" &&
                    $0.scopeId == targetScopeId
                }
            }()

            let isTheSameUser = user.userId == mainUser.userId

            if (isSuperAdmin || canManageOrgUser) && !isTheSameUser {
                Button {
                    VM.contextMenuUserIndex = index
                    VM.showEditUser.toggle()
                } label: {
                    Label("editButton", systemImage: "square.and.pencil")
                }

                Button {
                    VM.contextMenuUserIndex = index
                    VM.showResetPassword.toggle()
                } label: {
                    Label("resetPasswordButton", systemImage: "key.horizontal")
                }

                if isSuperAdmin {
                    if user.accountActive == "true" {
                        Button {
                            VM.contextMenuUserIndex = index
                            VM.alertMessage = "disableUserAccountConfirm".localized
                            VM.alertType = .disableUser
                            VM.showAlert = true
                        } label: {
                            Label("disableAccountButton", systemImage: "person.crop.circle.badge.xmark")
                        }
                    } else {
                        Button {
                            VM.contextMenuUserIndex = index
                            VM.alertMessage = "enableUserAccountConfirm".localized
                            VM.alertType = .enableUser
                            VM.showAlert = true
                        } label: {
                            Label("enableAccountButton", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }

                    Button(role: .destructive) {
                        VM.contextMenuUserIndex = index
                        VM.alertMessage = "deleteUserConfirm".localized
                        VM.alertType = .deleteUser
                        VM.showAlert = true
                    } label: {
                        Label("deleteUserButton", systemImage: "trash")
                    }
                }
            }
        }
    }
}
