import SwiftUI

struct UserDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: UsersViewModel
    @Binding var user: User

    @State private var expandedRoleNames: Set<String> = []
    @State private var shownRolePopover: String?
    @State private var createdByName: String = ""
    @State private var editedByName: String = ""

    private let userService = UserService()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                user.accountActive == "false"
                                    ? Color.red.opacity(0.12)
                                    : Color.fiitPrimary.opacity(0.12)
                            )
                            .frame(width: 72, height: 72)
                        Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)).uppercased())
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(user.accountActive == "false" ? .red : .fiitPrimary)
                    }

                    VStack(spacing: 4) {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.title3.weight(.semibold))
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if user.accountActive == "false" {
                        Text("accountDisabledLabel")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.1), in: Capsule())
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 0) {
                    infoRow(icon: "phone.fill", label: "Phone", value: user.phoneNumber)
                    Divider().padding(.leading, 52)
                    infoRow(icon: "house.fill", label: "Address", value: user.address)
                    Divider().padding(.leading, 52)
                    infoRow(icon: "calendar", label: "Birth Date", value: user.birthDate)

                    if !user.description.isEmpty {
                        Divider().padding(.leading, 52)
                        infoRow(icon: "text.quote", label: "Description", value: user.description)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("assignedRolesSection")
                            .font(.headline)

                        Spacer()

                        if let mainUser = session.mainUser {
                            let isSuperAdmin = mainUser.permissionsFlatList.contains { $0.permissionName == "EVERYTHING" }
                            let canManageOrgUser: Bool = {
                                guard let targetScopeId = user.permissionsFlatList.first(where: {
                                    $0.permissionName == "VIEW_ORGANIZATION" && $0.scopeType == "ORGANIZATION"
                                })?.scopeId else { return false }
                                return mainUser.permissionsFlatList.contains {
                                    $0.permissionName == "MANAGE_ROLES" && $0.scopeType == "ORGANIZATION" && $0.scopeId == targetScopeId
                                }
                            }()
                            let isTheSameUser = user.userId == mainUser.userId

                            if (isSuperAdmin || canManageOrgUser) && !isTheSameUser {
                                Button {
                                    VM.showAssignRole = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.fiitPrimary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    Divider().padding(.leading, 16)

                    if !user.userRoles.isEmpty {
                        ForEach(user.userRoles.sorted(by: { $0.scopeType.scopeOrder < $1.scopeType.scopeOrder }), id: \.id) { role in
                            let scopeKey = "\(role.scopeType)-\(role.scopeId ?? "-")"
                            if VM.scopeNames[scopeKey] != "Unknown" {
                                VStack(spacing: 0) {
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
                                                if shownRolePopover == role.roleName {
                                                    shownRolePopover = nil
                                                } else {
                                                    shownRolePopover = nil
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                        shownRolePopover = role.roleName
                                                    }
                                                }
                                            } label: {
                                                Image(systemName: "info.circle")
                                                    .foregroundStyle(.fiitPrimary)
                                            }
                                            .buttonStyle(.plain)
                                            .popover(
                                                isPresented: Binding(
                                                    get: { shownRolePopover == role.roleName },
                                                    set: { if !$0 { shownRolePopover = nil } }
                                                ),
                                                attachmentAnchor: .point(.trailing)
                                            ) {
                                                Text(role.roleDescription)
                                                    .padding()
                                                    .font(.caption)
                                                    .multilineTextAlignment(.leading)
                                                    .presentationCompactAdaptation(.popover)
                                            }

                                            Text(role.roleName.humanized)
                                                .font(.subheadline.weight(.medium))

                                            Spacer()

                                            if let scopeName = VM.scopeNames[scopeKey] {
                                                Text(scopeName)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .tint(Color.fiitPrimary)
                                    .onAppear {
                                        if let scopeId = role.scopeId {
                                            VM.getScopeName(scopeType: role.scopeType, scopeId: scopeId)
                                        } else if role.scopeType == "GLOBAL" {
                                            VM.scopeNames[scopeKey] = "Global"
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            VM.roleToRemove = AddRemoveRole(roleName: role.roleName, scopeType: role.scopeType, scopeID: role.scopeId ?? "0")
                                            VM.showRemoveRoleAlert = true
                                        } label: {
                                            Label("removeButton", systemImage: "xmark")
                                        }
                                    }

                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                    } else {
                        Text("noRolesAssigned")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(16)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 6) {
                    Text("activitySection")
                        .font(.headline)
                        .padding(.bottom, 4)

                    let created = user.createdAt?.toDate
                    let edited = user.lastEditAt?.toDate
                    let sameUser = user.createdBy == user.lastEditBy
                    let sameTime = created == edited

                    if let created, let _ = user.createdBy {
                        let creatorName = createdByName.isEmpty ? (user.createdBy ?? "-") : createdByName
                        let createdDate = created.formatted(date: .abbreviated, time: .shortened)
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle").font(.caption).foregroundStyle(.secondary)
                            (Text("createdByLabel") + Text(" \(creatorName), \(createdDate)")).font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    if !(sameUser && sameTime), let edited {
                        let editorName = editedByName.isEmpty ? (user.lastEditBy ?? "-") : editedByName
                        let editedDate = edited.formatted(date: .abbreviated, time: .shortened)
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle").font(.caption).foregroundStyle(.secondary)
                            (Text("editedByLabel") + Text(" \(editorName), \(editedDate)")).font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    if let lastLogin = user.lastLoginAt?.toDate {
                        let loginDate = lastLogin.formatted(date: .abbreviated, time: .shortened)
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.clock").font(.caption).foregroundStyle(.secondary)
                            (Text("lastLoginLabel") + Text(" \(loginDate)")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if let userId = user.createdBy {
                createdByName = await userService.resolveUserName(userId: userId)
            }
            if let userId = user.lastEditBy {
                editedByName = await userService.resolveUserName(userId: userId)
            }
        }
        .navigationTitle("userDetailTitle")
        .navigationBarTitleDisplayMode(.inline)
        .alert(VM.alertType?.alertTitle ?? "confirmActionTitle".localized, isPresented: $VM.showUserDetailsAlert) {
            Button(VM.alertType?.buttonLabel ?? "confirmButton".localized, role: .destructive) {
                switch VM.alertType {
                case .deleteUser:
                    VM.deleteUser(userID: user.userId)
                case .disableUser:
                    VM.disableUser(user: $user)
                case .enableUser:
                    VM.enableUser(user: $user)
                case .none:
                    break
                }
            }
            Button("cancelButton", role: .cancel) { }
        } message: {
            Text(VM.alertMessage)
        }
        .sheet(isPresented: $VM.showUserDetailsResetPassword) {
            UsersResetPasswordView(VM: VM, userID: user.userId)
        }
        .onChange(of: VM.userDeleted) {
            if VM.userDeleted {
                dismiss()
                VM.userDeleted = false
            }
        }
        .sheet(isPresented: $VM.showAssignRole) {
            NavigationStack {
                AssignNewRoleView(VM: VM, user: $user)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium, .large])
            }
        }
        .fullScreenCover(isPresented: $VM.showEditingUser) {
            NavigationStack {
                CreateUpdateUserView(
                    VM: VM,
                    existingUser: Binding<User?>(
                        get: { user },
                        set: { newValue in
                            if let updated = newValue {
                                user = updated
                            }
                        }
                    )
                )
                .navigationBarBackButtonHidden()
                .tint(Color.fiitPrimary)
            }
        }
        .alert("removeRoleButton", isPresented: $VM.showRemoveRoleAlert) {
            Button("removeButton", role: .destructive) {
                if let role = VM.roleToRemove {
                    VM.removeRole(roleToRemove: role, user: $user)
                }
            }
            Button("cancelButton", role: .cancel) {
                VM.roleToRemove = nil
            }
        } message: {
            if let role = VM.roleToRemove {
                Text("Are you sure you want to remove the role '\(role.roleName.humanized)'?")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let mainUser = session.mainUser {
                    let isSuperAdmin = mainUser.permissionsFlatList.contains { $0.permissionName == "EVERYTHING" }
                    let canManageOrgUser: Bool = {
                        guard let targetScopeId = user.permissionsFlatList.first(where: {
                            $0.permissionName == "VIEW_ORGANIZATION" && $0.scopeType == "ORGANIZATION"
                        })?.scopeId else { return false }
                        return mainUser.permissionsFlatList.contains {
                            $0.permissionName == "MANAGE_USERS" && $0.scopeType == "ORGANIZATION" && $0.scopeId == targetScopeId
                        }
                    }()
                    let isTheSameUser = user.userId == mainUser.userId

                    if (isSuperAdmin || canManageOrgUser) && !isTheSameUser {
                        Menu {
                            Button {
                                VM.showEditingUser.toggle()
                            } label: {
                                Label("editButton", systemImage: "square.and.pencil")
                            }

                            Button {
                                VM.showUserDetailsResetPassword.toggle()
                            } label: {
                                Label("resetPasswordButton", systemImage: "key.horizontal")
                            }

                            if mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) {
                                if user.accountActive == "true" {
                                    Button {
                                        VM.alertMessage = "disableUserAccountConfirm".localized
                                        VM.alertType = .disableUser
                                        VM.showUserDetailsAlert = true
                                    } label: {
                                        Label("disableAccountButton", systemImage: "person.crop.circle.badge.xmark")
                                    }
                                } else {
                                    Button {
                                        VM.alertMessage = "enableUserAccountConfirm".localized
                                        VM.alertType = .enableUser
                                        VM.showUserDetailsAlert = true
                                    } label: {
                                        Label("enableAccountButton", systemImage: "person.crop.circle.badge.checkmark")
                                    }
                                }

                                Button(role: .destructive) {
                                    VM.alertMessage = "deleteUserConfirm".localized
                                    VM.alertType = .deleteUser
                                    VM.showUserDetailsAlert = true
                                } label: {
                                    Label("deleteUserButton", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .imageScale(.large)
                                .foregroundStyle(.fiitPrimary)
                        }
                    }
                }
            }
        }
    }


    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(label))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func logRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
