
import SwiftUI

struct AccountMyRolesView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: AccountViewModel

    @State private var expandedRoleNames: Set<String> = []
    @State private var shownRolePopover: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.shield.checkmark")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("assignedRolesSection")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    if let user = session.mainUser {
                        if user.userRoles.isEmpty {
                            Text("noRolesAssignedDot")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(16)
                        } else {
                            ForEach(user.userRoles.sorted(by: { $0.scopeType.scopeOrder < $1.scopeType.scopeOrder }), id: \.id) { role in
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
                                                .foregroundStyle(.forText)

                                            Spacer()

                                            Text(VM.scopeNames["\(role.scopeType)-\(role.scopeId ?? "-")"] ?? (role.scopeId ?? role.scopeType.humanized))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .tint(Color.fiitPrimary)
                                    .onAppear {
                                        if let scopeId = role.scopeId {
                                            VM.getScopeName(scopeType: role.scopeType, scopeId: scopeId)
                                        }
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
        .navigationTitle("myRolesAndPermissionsTitle")
    }
}
