import SwiftUI
import SkeletonUI

struct LocationsView: View {
    @EnvironmentObject var session: UserSession
    @StateObject private var VM = LocationsViewModel()

    let organization: Organization

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if VM.isLoading {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { _ in
                                LocationSkeletonCellView()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                } else if VM.filteredLocations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(VM.filteredLocations) { location in
                                NavigationLink {
                                    ItemsView(VM: ItemsViewModel(organization: organization, location: location))
                                } label: {
                                    LocationCellView(VM: VM, organization: organization, location: location)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }

            if let mainUser = session.mainUser, !VM.locations.isEmpty,
               mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
                mainUser.permissionsFlatList.contains(where: { $0.permissionName == "CREATE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == organization.organizationId }) ||
                mainUser.permissionsFlatList.contains(where: { $0.permissionName == "CREATE_ITEM" && $0.scopeType == "LOCATION" && VM.locations.map({ $0.locationId }).contains($0.scopeId ?? "") }) {
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
                            CreateItemWizardView(VM: SingleItemViewModel(selectedOrganizationId: organization.id))
                        } else {
                            CreateItemView(VM: SingleItemViewModel(selectedOrganizationId: organization.id))
                        }
                    }
                }
            }
        }
        .navigationTitle(organization.name)
        .searchable(text: $VM.searchText)
        .toolbar {
            if let mainUser = session.mainUser {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarButton(mainUser: mainUser)
                }
            }
        }
        .navigationDestination(isPresented: $VM.showUsersSheet) {
            UsersView(organizationId: organization.organizationId)
        }
        .navigationDestination(isPresented: $VM.showGroupsSheet) {
            GroupsView(organization: organization)
        }
        .sheet(item: $VM.activeSheet) { item in
            NavigationStack {
                switch item {
                case .create:
                    CreateUpdateLocationView(VM: VM, organization: organization)
                case .edit(let location):
                    CreateUpdateLocationView(VM: VM, organization: organization, existingLocation: location)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("deleteLocationConfirm",
               isPresented: Binding(
                get: { VM.selectedLocationToDelete != nil },
                set: { if !$0 { VM.selectedLocationToDelete = nil } }
               ),
               presenting: VM.selectedLocationToDelete
        ) { location in
            Button("deleteButton", role: .destructive) {
                VM.deleteLocation(locationId: location.id)
                VM.selectedLocationToDelete = nil
            }
            Button("cancelButton", role: .cancel) {
                VM.selectedLocationToDelete = nil
            }
        } message: { location in
            Text("This will permanently remove location \"\(location.name)\".")
        }
        .onAppear {
            VM.getLocations(organizationId: organization.id)
        }
        .refreshable {
            VM.getLocations(organizationId: organization.id, forceRefresh: true)
        }
    }


    private func canCreateLocation(_ user: User) -> Bool {
        user.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
        user.permissionsFlatList.contains(where: { $0.permissionName == "CREATE_LOCATION" && $0.scopeType == "ORGANIZATION" && $0.scopeId == organization.organizationId })
    }

    private func canManageUsers(_ user: User) -> Bool {
        user.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
        user.permissionsFlatList.contains(where: { $0.permissionName == "MANAGE_USERS" && $0.scopeType == "ORGANIZATION" && $0.scopeId == organization.organizationId })
    }

    private func canManageGroups(_ user: User) -> Bool {
        user.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
        user.permissionsFlatList.contains(where: {
            $0.permissionName == "MANAGE_GROUP" &&
            $0.scopeType == "ORGANIZATION" &&
            $0.scopeId == organization.organizationId
        })
    }

    @ViewBuilder
    private func toolbarButton(mainUser: User) -> some View {
        let create = canCreateLocation(mainUser)
        let users = canManageUsers(mainUser)
        let groups = canManageGroups(mainUser)

        let count = [create, users, groups].filter { $0 }.count

        if count > 1 {
            Menu {
                if create {
                    Button {
                        VM.activeSheet = .create
                    } label: {
                        Label("newLocationTitle", systemImage: "plus")
                    }
                }
                if users {
                    Button {
                        VM.showUsersSheet = true
                    } label: {
                        Label("usersTitle", systemImage: "person.3")
                    }
                }
                if groups {
                    Button {
                        VM.showGroupsSheet = true
                    } label: {
                        Label("groupsTitle", systemImage: "person.2")
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(Color.fiitPrimary)
            }
        } else if create {
            Button {
                VM.activeSheet = .create
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.fiitPrimary)
            }
        } else if users {
            Button {
                VM.showUsersSheet = true
            } label: {
                Image(systemName: "person.3")
                    .foregroundStyle(Color.fiitPrimary)
            }
        } else if groups {
            Button {
                VM.showGroupsSheet = true
            } label: {
                Image(systemName: "person.2")
                    .foregroundStyle(Color.fiitPrimary)
            }
        }
    }


    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(.noLocations)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240)
                    .opacity(0.7)

                VStack(spacing: 8) {
                    Text(LocalizedStringKey(VM.searchText.isEmpty ? "noLocationsLabel" : "noResultsLabel"))
                        .font(.title2.weight(.bold))
                    Group {
                        if VM.searchText.isEmpty {
                            Text("noLocationsInOrganization")
                        } else {
                            Text("No location matches \"\(VM.searchText)\".")
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
}
