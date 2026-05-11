
import SwiftUI

struct MemberRolesView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: GroupsViewModel
    let group: OrganizationGroup
    let userID: String

    @State var groupMember: User? = nil
    @State private var shownRolePopover: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let user = groupMember {
                    let assignedLocationIDs = group.assignedLocations.map { $0.locationId }

                    let locationScopedRoles = user.userRoles.filter {
                        $0.scopeType == "LOCATION" && assignedLocationIDs.contains($0.scopeId ?? "")
                    }

                    let groupedRoles = Dictionary(grouping: locationScopedRoles) { role in
                        role.scopeId ?? "-"
                    }

                    if groupedRoles.isEmpty {
                        formCard {
                            sectionHeader(icon: "shield.slash", title: "assignedRolesSection")
                            Text("noRolesInGroupLocations")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    } else {
                        ForEach(groupedRoles.keys.sorted(), id: \.self) { locId in
                            let locName = group.assignedLocations.first(where: { $0.locationId == locId })?.name ?? "Unknown location"

                            formCard {
                                sectionHeader(icon: "mappin.and.ellipse", title: locName)

                                ForEach(Array((groupedRoles[locId] ?? []).enumerated()), id: \.element.id) { index, role in
                                    if index > 0 {
                                        Divider()
                                    }

                                    DisclosureGroup {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("permissionsLabel")
                                                .font(.subheadline)
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
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.forText)

                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .tint(.fiitPrimary)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            VM.roleToRemove = AddRemoveRole(roleName: role.roleName, scopeType: role.scopeType, scopeID: role.scopeId ?? "0")
                                            VM.showRemoveRoleAlert = true
                                        } label: {
                                            Label("removeButton", systemImage: "xmark")
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
        .navigationTitle("manageUserRolesTitle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                do {
                    self.groupMember = try await VM.getUserDetails(userID: userID)
                } catch {
                    print("Failed to fetch user:", error.localizedDescription)
                }
            }
        }
        .onChange(of: VM.userUpdated) {
            if VM.userUpdated {
                Task {
                    do {
                        self.groupMember = try await VM.getUserDetails(userID: userID)
                        VM.userUpdated = false
                    } catch {
                        print("Failed to fetch user:", error.localizedDescription)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    VM.showAssignRole = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.fiitPrimary)
                }
            }
        }
        .alert("removeRoleButton", isPresented: $VM.showRemoveRoleAlert) {
            Button("removeButton", role: .destructive) {
                if let role = VM.roleToRemove {
                    VM.removeRole(roleToRemove: role, groupID: group.groupId, userID: userID)
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
        .sheet(isPresented: $VM.showAssignRole) {
            NavigationStack {
                if let user = groupMember {
                    AssignRoleGroupView(VM: VM, group: group, user: user)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                }
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
