
import SwiftUI

struct AssignNewRoleView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: UsersViewModel
    @Binding var user: User

    @State private var expandedRoleNames: Set<String> = []
    @State private var shownRolePopover: String?

    @State private var selectedRole: Role? = nil
    @State private var selectedScopeID: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "person.badge.key.fill", title: "Select Role")

                    ForEach(VM.allRoles.sorted(by: { $0.scopeType.scopeOrder < $1.scopeType.scopeOrder }), id: \.id) { role in
                        let isSelected = selectedRole?.name == role.name && selectedRole?.scopeType == role.scopeType
                        let shouldShow = selectedRole == nil || isSelected

                        if shouldShow {
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
                                        .bold()
                                        .foregroundStyle(.forText)

                                    Spacer()

                                    Text(role.scopeType.humanized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.fiitPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.fiitPrimary.opacity(0.12), in: Capsule())
                                }
                            }
                            .tint(.fiitPrimary)
                            .padding(.vertical, 6)

                            if shouldShow && role.id != VM.allRoles.sorted(by: { $0.scopeType.scopeOrder < $1.scopeType.scopeOrder }).filter({ r in
                                let sel = selectedRole?.name == r.name && selectedRole?.scopeType == r.scopeType
                                return selectedRole == nil || sel
                            }).last?.id {
                                Divider()
                            }
                        }
                    }
                }

                formCard {
                    sectionHeader(icon: "scope", title: "Scope Selection")

                    Group {
                    switch selectedRole?.scopeType {
                    case "ORGANIZATION":
                        Picker("organizationColonLabel", selection: $selectedScopeID) {
                            Text("---").tag(nil as Int?)

                            ForEach(VM.organizations) { org in
                                Text(org.name).tag(org.id)
                            }
                        }
                        .tint(.forText)

                    case "GROUP":
                        Picker("groupColonLabel", selection: $selectedScopeID) {
                            Text("---").tag(nil as Int?)

                            ForEach(VM.organizations) { org in
                                HStack {
                                    Image(systemName: "building.2")
                                    Text(org.name)
                                }
                                .font(.headline)
                                .foregroundStyle(.gray)
                                .disabled(true)

                                ForEach(VM.groups.filter { $0.organizationId == org.organizationId }) { group in
                                    Text("    \(group.name)")
                                        .tag(group.id)
                                }
                            }
                        }
                        .tint(.forText)

                    case "LOCATION":
                        Picker("locationColonLabel", selection: $selectedScopeID) {
                            Text("---").tag(nil as Int?)

                            ForEach(VM.organizations) { org in
                                HStack {
                                    Image(systemName: "building.2")
                                    Text(org.name)
                                }
                                .font(.headline)
                                .foregroundStyle(.gray)
                                .disabled(true)

                                ForEach(VM.locations.filter { $0.organizationId == org.organizationId }) { loc in
                                    Text("    \(loc.name)")
                                        .tag(loc.id)
                                }
                            }
                        }
                        .tint(.forText)

                    case "GLOBAL":
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .foregroundStyle(.fiitPrimary)
                            Text("roleHasGlobalScope")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                    default:
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("selectRoleBeforeScopeHint")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    }
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
            if let user = session.mainUser {
                VM.getAllRoles(user: user)
                VM.getOrganizations(user: user)
            }
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
                    if let role = selectedRole {
                        let scopeIDString: String
                        if role.scopeType == "GLOBAL" {
                            scopeIDString = "0"
                        } else if let actualScopeID = selectedScopeID {
                            scopeIDString = String(actualScopeID)
                        } else {
                            return
                        }

                        VM.assignRole(roleToAssign: role, scopeID: scopeIDString, user: $user)
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(assignEnabled ? .fiitPrimary : .gray)
                .disabled(!assignEnabled)
            }
        }
    }

    private var assignEnabled: Bool {
        selectedRole != nil && (selectedRole?.scopeType == "GLOBAL" || selectedScopeID != nil)
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
