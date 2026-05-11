import Foundation
import SwiftUI

@MainActor
class GroupsViewModel: ObservableObject {
    @Published var groups: [OrganizationGroup] = []
    
    @Published var editingGroup: Bool = false
    @Published var groupToEdit: OrganizationGroup? = nil
    @Published var groupToDelete: OrganizationGroup? = nil
    @Published var groupForUserRemoval: OrganizationGroup? = nil
    @Published var userToRemoveFromGroup: GroupUser? = nil
    
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var selectedLocations: [Location] = []
    @Published var showLocations: Bool = false
    @Published var showCreateUpdateGroupSheet: Bool = false
    @Published var showAddUsersToGroup: Bool = false
    
    @Published var showAssignRole: Bool = false
    @Published var showRemoveUserAlert: Bool = false
    @Published var showDeleteGroupAler: Bool = false
    
    @Published var allLocations: [Location] = []
    @Published var selectedTenantID: Int? = nil
    @Published var allUsers: [User] = []
    @Published var allRoles: [Role] = []
    @Published var roleToRemove: AddRemoveRole? = nil
    @Published var showRemoveRoleAlert: Bool = false
    @Published var userUpdated: Bool = false
    @Published var isLoading: Bool = false

    private let orgService = OrganizationService()
    private let userService = UserService()
    private let authService = AuthService()

    var canUpdateGroup: Bool {
        guard let group = groupToEdit else { return false }
        
        let nameChanged = group.name != name
        let descriptionChanged = group.description != description
        let tenantChanged = Int(group.tenant?.userId ?? "") != selectedTenantID
        
        let oldLocationIDs = Set(group.assignedLocations.map { $0.id })
        let newLocationIDs = Set(selectedLocations.map { $0.id })
        let locationsChanged = oldLocationIDs != newLocationIDs
        
        return nameChanged || descriptionChanged || tenantChanged || locationsChanged
    }
    
    
    func getGroups(user: User, orgID: String, forceRefresh: Bool = false) {
        self.groups = []
        self.isLoading = true
        
        Task {
            if user.permissionsFlatList.contains(where: {
                $0.permissionName == "EVERYTHING" ||
                ($0.permissionName == "MANAGE_GROUP" && $0.scopeType == "ORGANIZATION" && $0.scopeId == orgID)
            }) {
                await getAllGroups(orgID: orgID, forceRefresh: forceRefresh)
            } else {
                let groupIDs = Set(
                    user.permissionsFlatList
                        .filter { $0.scopeType == "GROUP" }
                        .compactMap { $0.scopeId }
                )
                
                await withTaskGroup(of: Void.self) { taskGroup in
                    for groupID in groupIDs {
                        taskGroup.addTask { await self.getGroup(groupID: groupID, filterOrgID: orgID) }
                    }
                }
            }
            self.isLoading = false
        }
    }
    
    func getAllGroups(orgID: String, forceRefresh: Bool = false) async {
        do {
            let responseGroups = try await orgService.getGroups(forceRefresh: forceRefresh)
            self.groups = responseGroups.filter { $0.organizationId == orgID }
        } catch {
            handleError(error)
        }
    }
    
    func getGroup(groupID: String, filterOrgID: String? = nil) async {
        do {
            let responseGroup = try await orgService.getGroupDetails(groupId: groupID)
            
            if let orgID = filterOrgID, responseGroup.organizationId != orgID { return }
            
            if let index = self.groups.firstIndex(where: { $0.groupId == responseGroup.groupId }) {
                self.groups[index] = responseGroup
            } else {
                self.groups.append(responseGroup)
            }
        } catch {
            handleError(error)
        }
    }
    
    func getLocations(organizationId: Int, forceRefresh: Bool = false) {
        Task {
            do {
                self.allLocations = try await orgService.getLocations(organizationId: organizationId, forceRefresh: forceRefresh)
            } catch {
                handleError(error)
            }
        }
    }
    
    func getUsers(organizationID: String, groupID: String, forceRefresh: Bool = false) {
        Task {
            do {
                let responseUsers = try await userService.getUsers(forceRefresh: forceRefresh)
                self.allUsers = responseUsers.filter { user in
                    let hasOrgPermission = user.permissionsFlatList.contains {
                        $0.scopeType == "ORGANIZATION" && $0.scopeId == organizationID
                    }
                    let alreadyInGroup = user.permissionsFlatList.contains {
                        $0.scopeType == "GROUP" && $0.scopeId == groupID
                    }
                    return hasOrgPermission && (groupID == "0" || !alreadyInGroup)
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func getUserDetails(userID: String) async throws -> User {
        return try await userService.getUserDetails(userID: userID)
    }
    
    
    func createGroup(organizationID: String) {
        Task {
            let locationIDs = selectedLocations.map { $0.locationId }
            let request = CreateUpdateGroupRequest(name: name, description: description, organizationID: organizationID, locations: locationIDs)
            
            do {
                let newGroup = try await orgService.createGroup(newGroup: request)
                self.groups.append(newGroup)
                
                if let tenantID = self.selectedTenantID {
                    await assignTenant(groupID: newGroup.groupId, tenantID: String(tenantID))
                }
                self.showCreateUpdateGroupSheet = false
            } catch {
                handleError(error)
            }
        }
    }
    
    func updateGroup(organizationID: String, groupID: String) {
        Task {
            let locationIDs = selectedLocations.map { $0.locationId }
            let request = CreateUpdateGroupRequest(name: name, description: description, organizationID: organizationID, locations: locationIDs)
            
            do {
                let updatedGroup = try await orgService.updateGroup(existingGroup: request, groupID: groupID)
                
                if let index = self.groups.firstIndex(where: { $0.groupId == groupID }) {
                    self.groups[index] = updatedGroup
                }
                
                let oldTenantID = updatedGroup.tenant?.userId
                let newTenantID = self.selectedTenantID.map(String.init)
                
                if oldTenantID != newTenantID {
                    if let old = oldTenantID { await removeTenant(groupID: groupID, tenantID: old) }
                    if let new = newTenantID { await assignTenant(groupID: groupID, tenantID: new) }
                }
                
                self.showCreateUpdateGroupSheet = false
            } catch {
                handleError(error)
            }
        }
    }
    
    func deleteGroup(groupID: String) {
        Task {
            do {
                try await orgService.deleteGroup(groupID: groupID)
                self.groups.removeAll(where: { $0.groupId == groupID })
            } catch {
                handleError(error)
            }
        }
    }
    
    
    func assignTenant(groupID: String, tenantID: String) async {
        let tenantRole = AddRemoveRole(roleName: "TENANT", scopeType: "GROUP", scopeID: groupID)
        do {
            try await userService.assignRole(roleToAssign: tenantRole, userID: tenantID)
            await getGroup(groupID: groupID)
        } catch {
            handleError(error)
        }
    }
    
    func removeTenant(groupID: String, tenantID: String) async {
        let tenantRole = AddRemoveRole(roleName: "TENANT", scopeType: "GROUP", scopeID: groupID)
        do {
            try await userService.removeRole(roleToRemove: tenantRole, userID: tenantID)
            await getGroup(groupID: groupID)
        } catch {
            handleError(error)
        }
    }
    
    func addUsersToGroup(groupID: String, memberIDs: [String]) {
        Task {
            await withTaskGroup(of: Void.self) { taskGroup in
                for memberID in memberIDs {
                    taskGroup.addTask {
                        let memberRole = AddRemoveRole(roleName: "GROUP_MEMBER", scopeType: "GROUP", scopeID: groupID)
                        do {
                            try await self.userService.assignRole(roleToAssign: memberRole, userID: memberID)
                        } catch {
                            print("role assign failed: \(memberID)")
                        }
                    }
                }
            }
            await getGroup(groupID: groupID)
            self.showAddUsersToGroup = false
        }
    }
    
    func removeUserFromRole(groupID: String, memberID: String) {
        Task {
            let memberRole = AddRemoveRole(roleName: "GROUP_MEMBER", scopeType: "GROUP", scopeID: groupID)
            do {
                try await userService.removeRole(roleToRemove: memberRole, userID: memberID)
                await getGroup(groupID: groupID)
            } catch {
                handleError(error)
            }
        }
    }
    
    func removeRole(roleToRemove: AddRemoveRole, groupID: String, userID: String) {
        Task {
            do {
                try await orgService.removeGroupRole(roleToRemove: roleToRemove, userID: userID, groupID: groupID)
                self.userUpdated = true
            } catch {
                handleError(error)
            }
        }
    }
    
    func assignRole(roleToAssign: AddRemoveRole, groupID: String, userID: String) {
        Task {
            do {
                try await orgService.assignGroupRole(roleToAssign: roleToAssign, userID: userID, groupID: groupID)
                self.userUpdated = true
                self.showAssignRole = false
            } catch {
                handleError(error)
            }
        }
    }
    
    func getAllRoles(user: User, group: OrganizationGroup) {
        Task {
            do {
                let roles = try await orgService.getRolesGroup()
                let assignedLocationIDs = group.assignedLocations.map { $0.locationId }
                
                self.allRoles = roles.filter { role in
                    let userHasIn = user.userRoles.filter { $0.roleName == role.name && $0.scopeType == "LOCATION" }
                    let userScopedLocationIDs = Set(userHasIn.compactMap { $0.scopeId })
                    return assignedLocationIDs.contains(where: { !userScopedLocationIDs.contains($0) })
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }
    
    @ViewBuilder
    func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text("\(label)").foregroundStyle(.gray)
                Text("*").foregroundStyle(.red)
            }
            TextField("", text: text)
        }
    }
}
