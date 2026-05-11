import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: GroupsViewModel = GroupsViewModel()
    let organization: Organization

    var body: some View {
        Group {
            if VM.isLoading {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            GroupSkeletonCellView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(Color(.systemGroupedBackground))
            } else if VM.groups.isEmpty {
                ScrollView {
                    VStack(spacing: 20) {
                        Image(.noGroups)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240)
                            .opacity(0.7)

                        VStack(spacing: 8) {
                            Text("noGroupsLabel")
                                .font(.title2.weight(.bold))
                            Text("noGroupsInOrganization")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)
                    .padding(.top, 40)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(VM.groups) { group in
                            GroupCellView(VM: VM, organization: organization, group: group)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("groupsTitle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let mainUser = session.mainUser {
                VM.getGroups(user: mainUser, orgID: organization.organizationId)
            }
        }
        .refreshable {
            if let mainUser = session.mainUser {
                VM.getGroups(user: mainUser, orgID: organization.organizationId, forceRefresh: true)
            }
        }
        .sheet(isPresented: $VM.showCreateUpdateGroupSheet) {
            NavigationStack {
                CreateUpdateGroupView(VM: VM, organization: organization)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(isPresented: $VM.showAddUsersToGroup) {
            NavigationStack {
                if let group = VM.groupToEdit {
                    AddGroupMembersView(VM: VM, group: group)
                }
            }
        }
        .toolbar {
            if let mainUser = session.mainUser,
               mainUser.permissionsFlatList.contains(where: {
                   ($0.permissionName.caseInsensitiveCompare("MANAGE_ROLES") == .orderedSame &&
                    $0.scopeType == "ORGANIZATION" &&
                    $0.scopeId == organization.organizationId)
                   ||
                   ($0.permissionName.caseInsensitiveCompare("EVERYTHING") == .orderedSame &&
                    $0.scopeType == "GLOBAL")
               }) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        VM.editingGroup = false
                        VM.name = ""
                        VM.description = ""
                        VM.selectedTenantID = nil
                        VM.selectedLocations = []
                        VM.groupToEdit = nil
                        VM.showCreateUpdateGroupSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.fiitPrimary)
                    }
                }
            }
        }
        .alert("deleteGroupConfirm",
               isPresented: Binding(get: {
            VM.groupToDelete != nil
        }, set: { newVal in
            if !newVal { VM.groupToDelete = nil }
        }),
               presenting: VM.groupToDelete) { group in
            Button("deleteButton", role: .destructive) {
                VM.deleteGroup(groupID: group.groupId)
            }
            Button("cancelButton", role: .cancel) {}
        } message: { group in
            Text("This will permanently delete the group \"\(group.name)\".")
        }
        .alert("removeUserFromGroupConfirm",
               isPresented: Binding(get: {
            VM.userToRemoveFromGroup != nil
        }, set: { newVal in
            if !newVal { VM.userToRemoveFromGroup = nil }
        }),
               presenting: VM.userToRemoveFromGroup) { user in
            Button("removeButton", role: .destructive) {
                if let group = VM.groupForUserRemoval {
                    VM.removeUserFromRole(groupID: group.groupId, memberID: user.userId)
                }
            }
            Button("cancelButton", role: .cancel) {}
        } message: { user in
            Text("User \(user.firstName) \(user.lastName) will be removed from this group.")
        }
    }
}
