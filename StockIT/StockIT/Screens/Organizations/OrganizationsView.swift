import SwiftUI

struct OrganizationsView: View {
    @EnvironmentObject var session: UserSession
    @StateObject private var VM = OrganizationsViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if VM.isLoading {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { _ in
                                OrganizationSkeletonCellView()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                } else if VM.filteredOrganizations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(VM.filteredOrganizations) { organization in
                                NavigationLink {
                                    LocationsView(organization: organization)
                                } label: {
                                    OrganizationCellView(VM: VM, organization: organization)
                                }
                                .contextMenu {
                                    contextMenuContent(for: organization)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }

            if session.mainUser?.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" || $0.permissionName == "CREATE_ITEM" }) == true && !VM.organizations.isEmpty {
                Button {
                    VM.showCreateItemView = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 56, height: 56)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [Color.fiitPrimary, Color.fiitPrimary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .shadow(color: Color.fiitPrimary.opacity(0.35), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .fullScreenCover(isPresented: $VM.showCreateItemView) {
                    NavigationStack {
                        if VM.useWizard {
                            CreateItemWizardView(VM: SingleItemViewModel())
                        } else {
                            CreateItemView(VM: SingleItemViewModel())
                        }
                    }
                }
            }
        }
        .navigationTitle("organizationsTitle")
        .searchable(text: $VM.searchText)
        .navigationDestination(isPresented: $VM.showUsersSheet) {
            NavigationStack {
                UsersView()
            }
        }
        .navigationDestination(isPresented: $VM.showGroups) {
            if let org = VM.selectedContextOrganization {
                NavigationStack {
                    GroupsView(organization: org)
                }
            }
        }
        .sheet(item: $VM.activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .createOrganization:
                    CreateUpdateOrganizationView(VM: VM)
                case .editOrganization(let organization):
                    CreateUpdateOrganizationView(VM: VM, existingOrganization: organization)
                }
            }
            .presentationDragIndicator(.visible)
        }
        .alert("deleteOrganizationConfirm",
               isPresented: Binding(
                get: { VM.selectedOrganizationToDelete != nil },
                set: { if !$0 { VM.selectedOrganizationToDelete = nil } }
               ),
               presenting: VM.selectedOrganizationToDelete
        ) { organization in
            Button("deleteButton", role: .destructive) {
                VM.deleteOrganization(organizationId: organization.id)
                VM.selectedOrganizationToDelete = nil
            }
            Button("cancelButton", role: .cancel) {
                VM.selectedOrganizationToDelete = nil
            }
        } message: { organization in
            Text("This will permanently remove organization \"\(organization.name)\".")
        }
        .toolbar {
            if session.mainUser?.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) == true {
                ToolbarItemGroup(placement: .topBarLeading) {
                    NavigationLink(destination: UsersView()) {
                        Image(systemName: "person.2")
                            .foregroundStyle(Color.fiitPrimary)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        VM.activeSheet = .createOrganization
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.fiitPrimary)
                    }
                }
            }
        }
        .onAppear {
            VM.getOrganizations()
            if let mainUser = session.mainUser {
                VM.getGroups(user: mainUser)
            }
        }
        .refreshable {
            VM.getOrganizations(forceRefresh: true)
        }
    }


    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(.noOrganizations)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240)
                    .opacity(0.7)

                VStack(spacing: 8) {
                    Text(LocalizedStringKey(VM.searchText.isEmpty ? "noOrganizationsLabel" : "noResultsLabel"))
                        .font(.title2.weight(.bold))
                    Group {
                        if VM.searchText.isEmpty {
                            Text("noOrganizationsYet")
                        } else {
                            Text("No organization matches \"\(VM.searchText)\".")
                        }
                    }
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
    }


    @ViewBuilder
    private func contextMenuContent(for organization: Organization) -> some View {
        if let mainUser = session.mainUser {
            if mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
                mainUser.permissionsFlatList.contains(where: { $0.permissionName == "MANAGE_USERS" && $0.scopeType == "ORGANIZATION" && $0.scopeId == organization.organizationId }) {
                Button {
                    VM.selectedContextOrganization = organization
                    VM.showUsersSheet = true
                } label: {
                    Label("usersTitle", systemImage: "person.3")
                }
            }

            if mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
                mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "MANAGE_GROUP" &&
                    $0.scopeType == "ORGANIZATION" &&
                    $0.scopeId == organization.organizationId
                }) ||
                mainUser.permissionsFlatList.contains(where: { perm in
                    perm.scopeType == "GROUP" &&
                    VM.groups.contains(where: { $0.groupId == perm.scopeId && $0.organizationId == organization.organizationId })
                }) {
                Button {
                    VM.selectedContextOrganization = organization
                    VM.showGroups = true
                } label: {
                    Label("groupsTitle", systemImage: "person.2")
                }
            }

            if mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
                mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EDIT_ORGANIZATION" && $0.scopeType == "ORGANIZATION" && $0.scopeId == organization.organizationId }) {
                Button {
                    VM.activeSheet = .editOrganization(organization)
                } label: {
                    Label("editButton", systemImage: "square.and.pencil")
                }
            }

            if mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) {
                Button(role: .destructive) {
                    VM.selectedOrganizationToDelete = organization
                } label: {
                    Label("deleteButton", systemImage: "trash")
                }
            }
        }
    }
}
