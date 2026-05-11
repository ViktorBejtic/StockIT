import SwiftUI

struct GroupCellView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: GroupsViewModel
    let organization: Organization
    let group: OrganizationGroup

    @State private var createdByName: String = ""
    @State private var editedByName: String = ""

    private let userService = UserService()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.fiitPrimary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.fiitPrimary)
                }

                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.forText)

                Spacer()

                if let mainUser = session.mainUser,
                   mainUser.permissionsFlatList.contains(where: {
                       ($0.permissionName.caseInsensitiveCompare("MANAGE_GROUP") == .orderedSame &&
                        $0.scopeType == "ORGANIZATION" &&
                        $0.scopeId == organization.organizationId)
                       ||
                       ($0.permissionName.caseInsensitiveCompare("EVERYTHING") == .orderedSame &&
                        $0.scopeType == "GLOBAL")
                   }) {
                    Menu {
                        Button {
                            VM.editingGroup = true
                            VM.name = group.name
                            VM.description = group.description
                            VM.selectedTenantID = Int(group.tenant?.userId ?? "")
                            VM.selectedLocations = group.assignedLocations.map { Location(from: $0) }
                            VM.groupToEdit = group
                            VM.showCreateUpdateGroupSheet.toggle()
                        } label: {
                            Label("editButton", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            VM.groupToDelete = group
                        } label: {
                            Label("deleteButton", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if !group.description.isEmpty {
                Text(group.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.fiitPrimary)
                    Text("locationsTitle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if group.assignedLocations.isEmpty {
                    Text("noLocationsAssigned")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(group.assignedLocations) { loc in
                            Text(loc.name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.fiitPrimary.opacity(0.1), in: Capsule())
                                .foregroundStyle(.fiitPrimary)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.fiitPrimary)
                        Text("membersLabel")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if let mainUser = session.mainUser,
                       mainUser.permissionsFlatList.contains(where: {
                           ($0.permissionName.caseInsensitiveCompare("MANAGE_ROLES") == .orderedSame &&
                            $0.scopeType == "ORGANIZATION" &&
                            $0.scopeId == organization.organizationId)
                           ||
                           ($0.permissionName.caseInsensitiveCompare("EVERYTHING") == .orderedSame &&
                            $0.scopeType == "GLOBAL")
                       }) {
                        Spacer()
                        Button {
                            VM.groupToEdit = group
                            VM.showAddUsersToGroup = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.fiitPrimary)
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let tenant = group.tenant {
                    memberRow(name: "\(tenant.firstName) \(tenant.lastName)", isTenant: true)
                }

                if let members = group.members {
                    ForEach(members.filter { $0.userId != group.tenant?.userId }) { user in
                        NavigationLink {
                            MemberRolesView(VM: VM, group: group, userID: user.userId)
                        } label: {
                            memberRow(name: "\(user.firstName) \(user.lastName)", isTenant: false)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                VM.groupForUserRemoval = group
                                VM.userToRemoveFromGroup = user
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }

                if group.tenant == nil && (group.members == nil || group.members!.isEmpty) {
                    Text("noMembersAssigned")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            let created = group.createdAt?.toDate
            let edited = group.lastEditAt?.toDate
            let sameUser = group.createdBy == group.lastEditBy
            let sameTime = created == edited

            if let created, let creator = group.createdBy {
                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 4) {
                    let creatorName = createdByName.isEmpty ? creator : createdByName
                    let createdDateStr = created.formatted(date: .abbreviated, time: .shortened)
                    (Text("createdByLabel") + Text(" \(creatorName), \(createdDateStr)"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if !(sameUser && sameTime) {
                        let editorName = editedByName.isEmpty ? (group.lastEditBy ?? "-") : editedByName
                        let editedDateStr = edited?.formatted(date: .abbreviated, time: .shortened) ?? "-"
                        (Text("editedByLabel") + Text(" \(editorName), \(editedDateStr)"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .task {
            if let userId = group.createdBy {
                createdByName = await userService.resolveUserName(userId: userId)
            }
            if let userId = group.lastEditBy {
                editedByName = await userService.resolveUserName(userId: userId)
            }
        }
    }


    private func memberRow(name: String, isTenant: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isTenant ? Color.yellow.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 30, height: 30)
                Text(String(name.prefix(1)).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isTenant ? .yellow : .secondary)
            }

            Text(name)
                .font(.subheadline)
                .foregroundStyle(.forText)

            Spacer()

            if isTenant {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("tenantLabel")
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
            }
        }
        .padding(.vertical, 2)
    }
}


struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}
