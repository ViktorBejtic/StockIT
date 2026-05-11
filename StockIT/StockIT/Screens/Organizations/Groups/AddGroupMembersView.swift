
import SwiftUI

struct AddGroupMembersView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: GroupsViewModel
    let group: OrganizationGroup

    @State private var selectedUserIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "person.2.fill", title: "Available Users")

                    if VM.allUsers.isEmpty {
                        Text("noUsersAvailableToAdd")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(VM.allUsers.enumerated()), id: \.element.id) { index, user in
                            let isSelected = selectedUserIDs.contains(user.userId)

                            if index > 0 {
                                Divider().padding(.leading, 58)
                            }

                            Button {
                                if isSelected {
                                    selectedUserIDs.remove(user.userId)
                                } else {
                                    selectedUserIDs.insert(user.userId)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.fiitPrimary.opacity(0.12))
                                            .frame(width: 44, height: 44)

                                        Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)).uppercased())
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.fiitPrimary)
                                    }

                                    Text("\(user.firstName) \(user.lastName)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.forText)

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                        .font(.title3)
                                        .foregroundStyle(.fiitPrimary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("addMembersButton")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("cancelButton") {
                    VM.showAddUsersToGroup = false
                }
                .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("addButton") {
                    VM.addUsersToGroup(groupID: group.groupId, memberIDs: Array(selectedUserIDs))
                }
                .fontWeight(.semibold)
                .foregroundStyle(selectedUserIDs.isEmpty ? .gray : .fiitPrimary)
                .disabled(selectedUserIDs.isEmpty)
            }
        }
        .onAppear {
            VM.getUsers(organizationID: group.organizationId, groupID: group.groupId)
        }
        .refreshable {
            VM.getUsers(organizationID: group.organizationId, groupID: group.groupId, forceRefresh: true)
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
