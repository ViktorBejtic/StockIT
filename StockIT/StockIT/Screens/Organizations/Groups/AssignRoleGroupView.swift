
import SwiftUI

struct AssignRoleGroupView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: GroupsViewModel
    let group: OrganizationGroup
    let user: User

    @State private var expandedRoleNames: Set<String> = []
    @State private var shownRolePopover: String?

    @State private var selectedRole: Role? = nil
    @State private var selectedScopeID: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "shield.checkered", title: "Select Role")

                    ForEach(Array(VM.allRoles.sorted(by: { $0.scopeType.scopeOrder < $1.scopeType.scopeOrder }).enumerated()), id: \.element.id) { index, role in
                        let isSelected = selectedRole?.name == role.name && selectedRole?.scopeType == role.scopeType
                        let shouldShow = selectedRole == nil || isSelected

                        if shouldShow {
                            if index > 0 {
                                Divider()
                            }

                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(role.description)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.forText)

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
                                        if selectedRole?.name == role.name && selectedRole?.scopeType == role.scopeType {
                                            selectedRole = nil
                                            selectedScopeID = nil
                                        } else {
                                            selectedRole = role
                                        }
                                    } label: {
                                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(.fiitPrimary)
                                    }
                                    .buttonStyle(.plain)

                                    Text(role.name.humanized)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.forText)

                                    Spacer()

                                    Text(role.scopeType.humanized)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.fiitPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.fiitPrimary.opacity(0.1), in: Capsule())
                                }
                            }
                            .padding(.vertical, 6)
                            .tint(.fiitPrimary)
                        }
                    }
                }

                formCard {
                    sectionHeader(icon: "mappin.and.ellipse", title: "Select Location")

                    Picker("locationColonLabel", selection: $selectedScopeID) {
                        Text("---").tag(nil as Int?)

                        ForEach(
                            VM.allLocations.filter { loc in
                                group.assignedLocations.contains(where: { $0.locationId == loc.locationId }) &&
                                !(user.userRoles.contains {
                                    $0.scopeType == "LOCATION" &&
                                    $0.scopeId == loc.locationId &&
                                    $0.roleName == selectedRole?.name
                                })
                            }
                        ) { loc in
                            Text(loc.name)
                                .tag(loc.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.forText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("assignNewRoleTitle")
        .onAppear {
            VM.getAllRoles(user: user, group: group)
            VM.getLocations(organizationId: Int(group.organizationId) ?? 0)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancelButton") {
                    VM.showAssignRole = false
                }
                .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("assignButton") {
                    if let role = selectedRole, let scopeID = selectedScopeID {
                        let scopeIDString = String(scopeID)
                        let roleToAssign = AddRemoveRole(roleName: role.name, scopeType: role.scopeType, scopeID: scopeIDString)
                        VM.assignRole(roleToAssign: roleToAssign, groupID: group.groupId, userID: user.userId)
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle((selectedRole == nil || selectedScopeID == nil) ? .gray : .fiitPrimary)
                .disabled(selectedRole == nil || selectedScopeID == nil)
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
