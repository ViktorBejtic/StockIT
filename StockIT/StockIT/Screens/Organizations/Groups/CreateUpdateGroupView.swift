import SwiftUI

struct CreateUpdateGroupView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: GroupsViewModel
    let organization: Organization

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                formCard {
                    sectionHeader(icon: "person.3.fill", title: "Group Info")
                    styledField(icon: "textformat", label: "Group Name", placeholder: "Enter group name", text: $VM.name)
                    Divider().padding(.leading, 44)
                    styledField(icon: "text.alignleft", label: "Description", placeholder: "What is this group for?", text: $VM.description)
                }

                formCard {
                    HStack {
                        sectionHeader(icon: "mappin.and.ellipse", title: "locationsTitle")
                        Text("*").foregroundStyle(.red).font(.headline)
                        Spacer()

                        if !VM.selectedLocations.isEmpty {
                            Button {
                                VM.showLocations = true
                            } label: {
                                Text("editButton")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.fiitPrimary)
                            }
                        }
                    }

                    if VM.selectedLocations.isEmpty {
                        Button {
                            VM.showLocations = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.fiitPrimary)
                                Text("selectLocationsTitle")
                                    .font(.subheadline)
                                    .foregroundStyle(.fiitPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.fiitPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        FlowLayout(spacing: 6) {
                            ForEach(VM.selectedLocations) { location in
                                HStack(spacing: 4) {
                                    Text(location.name)
                                        .font(.caption)

                                    Button {
                                        if let index = VM.selectedLocations.firstIndex(where: { $0.id == location.id }) {
                                            VM.selectedLocations.remove(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.fiitPrimary.opacity(0.1), in: Capsule())
                                .foregroundStyle(.fiitPrimary)
                            }
                        }
                    }
                }

                if let mainUser = session.mainUser,
                   mainUser.permissionsFlatList.contains(where: {
                       ($0.permissionName.caseInsensitiveCompare("MANAGE_ROLES") == .orderedSame &&
                        $0.scopeType == "ORGANIZATION" &&
                        $0.scopeId == organization.organizationId) ||
                       ($0.permissionName.caseInsensitiveCompare("EVERYTHING") == .orderedSame &&
                        $0.scopeType == "GLOBAL")
                   }) {
                    formCard {
                        sectionHeader(icon: "star.fill", title: "Group Tenant")

                        Picker("", selection: $VM.selectedTenantID) {
                            Text("noTenantLabel").tag(nil as Int?)
                            ForEach(VM.allUsers) { user in
                                Text("\(user.firstName) \(user.lastName)").tag(user.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.forText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizedStringKey(VM.editingGroup ? "updateGroupTitle" : "createGroupTitle"))
        .onAppear {
            VM.getLocations(organizationId: organization.id)
            VM.getUsers(organizationID: organization.organizationId, groupID: "0")
        }
        .fullScreenCover(isPresented: $VM.showLocations) {
            NavigationStack {
                SelectLocationsView(
                    VM: VM,
                    selectedLocations: VM.selectedLocations,
                    organization: organization
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    VM.showCreateUpdateGroupSheet = false
                } label: {
                    Text("cancelButton")
                        .foregroundStyle(.fiitPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if VM.editingGroup {
                        if let group = VM.groupToEdit {
                            VM.updateGroup(organizationID: organization.organizationId, groupID: group.groupId)
                        }
                    } else {
                        VM.createGroup(organizationID: organization.organizationId)
                    }
                } label: {
                    Text(LocalizedStringKey(VM.editingGroup ? "updateButton" : "createButton"))
                        .fontWeight(.semibold)
                        .foregroundStyle(buttonEnabled ? .fiitPrimary : .gray)
                }
                .disabled(!buttonEnabled)
            }
        }
    }

    private var buttonEnabled: Bool {
        if VM.editingGroup {
            return VM.canUpdateGroup
        }
        return !VM.name.isEmpty && !VM.description.isEmpty && !VM.selectedLocations.isEmpty
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

    private func styledField(icon: String, label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(label))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(LocalizedStringKey(placeholder), text: text)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}
