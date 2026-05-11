import SwiftUI

struct LocationCellView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: LocationsViewModel
    let organization: Organization
    let location: Location

    private var initials: String {
        let words = location.name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(location.name.prefix(2)).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.fiitPrimary.opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 22))
                    .foregroundStyle(.fiitPrimary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(location.name)
                    .font(.headline)
                    .foregroundStyle(.forText)
                    .lineLimit(1)

                if let room = location.room, !room.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "door.left.hand.open")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(room)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !location.description.isEmpty {
                    Text(location.description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(location.itemCount)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.fiitPrimary)
                Text("itemsCountLabel")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.forText)
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
        .contextMenu {
            if location.id != -1, let mainUser = session.mainUser {
                if mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "EVERYTHING" ||
                    ($0.permissionName == "EDIT_LOCATION"
                     && $0.scopeType == "LOCATION"
                     && $0.scopeId == location.locationId) ||
                    ($0.permissionName == "EDIT_LOCATION"
                     && $0.scopeType == "ORGANIZATION"
                     && $0.scopeId == location.organizationId)
                }) {
                    Button {
                        VM.activeSheet = .edit(location)
                    } label: {
                        Label("editButton", systemImage: "square.and.pencil")
                    }
                }

                if mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "EVERYTHING" ||
                    ($0.permissionName == "DELETE_LOCATION"
                     && $0.scopeType == "LOCATION"
                     && $0.scopeId == location.locationId) ||
                    ($0.permissionName == "DELETE_LOCATION"
                     && $0.scopeType == "ORGANIZATION"
                     && $0.scopeId == location.organizationId)
                }) {
                    Button(role: .destructive) {
                        VM.selectedLocationToDelete = location
                    } label: {
                        Label("deleteButton", systemImage: "trash")
                    }
                }
            }
        }
    }
}
