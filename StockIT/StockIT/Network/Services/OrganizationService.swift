import Foundation

class OrganizationService {
    private let client = NetworkClient.shared
    
    func getOrganizations(forceRefresh: Bool = false) async throws -> [Organization] {
        if !forceRefresh {
            if let cached = try? APICacheManager.shared.organizationsStorage?.object(forKey: "all_orgs") {
                return cached
            }
        }
        
        let fetched: [Organization] = try await client.request(path: "organizations")

        try? APICacheManager.shared.organizationsStorage?.setObject(fetched, forKey: "all_orgs")
        
        return fetched
    }
    
    func getOrganizationDetails(organizationId: String) async throws -> Organization {
        return try await client.request(path: "organizations/\(organizationId)")
    }
    
    func createOrganization(newOrganization: CreateUpdateOrganizationRequest) async throws -> Organization {
        let org: Organization = try await client.request(path: "organizations", method: .post, body: newOrganization)
        try? APICacheManager.shared.organizationsStorage?.removeObject(forKey: "all_orgs")
        return org
    }
    
    func updateOrganization(existingOrganization: CreateUpdateOrganizationRequest, organizationId: Int) async throws -> Organization {
        let org: Organization = try await client.request(path: "organizations/\(organizationId)", method: .put, body: existingOrganization)
        try? APICacheManager.shared.organizationsStorage?.removeObject(forKey: "all_orgs")
        return org
    }
    
    func deleteOrganization(organizationId: Int) async throws {
        try await client.requestVoid(path: "organizations/\(organizationId)", method: .delete)
        try? APICacheManager.shared.organizationsStorage?.removeObject(forKey: "all_orgs")
    }
    
    func getLocations(organizationId: Int, forceRefresh: Bool = false) async throws -> [Location] {
        let cacheKey = "locations_org_\(organizationId)"
        
        if !forceRefresh {
            if let cached = try? APICacheManager.shared.locationsStorage?.object(forKey: cacheKey) {
                return cached
            }
        }
        
        let response: GetLocationsResponse = try await client.request(path: "organizations/\(organizationId)/locations")

        try? APICacheManager.shared.locationsStorage?.setObject(response.locations, forKey: cacheKey)
        
        return response.locations
    }
    
    func getLocationDetails(locationId: String) async throws -> Location {
        return try await client.request(path: "locations/\(locationId)")
    }
    
    func createLocation(newLocation: CreateUpdateLocationRequest) async throws -> Location {
        let loc: Location = try await client.request(path: "locations", method: .post, body: newLocation)
        try? APICacheManager.shared.locationsStorage?.removeAll()
        return loc
    }
    
    func updateLocation(existingLocation: CreateUpdateLocationRequest, locationId: Int) async throws -> Location {
        let loc: Location = try await client.request(path: "locations/\(locationId)", method: .put, body: existingLocation)
        try? APICacheManager.shared.locationsStorage?.removeAll()
        return loc
    }
    
    func deleteLocation(locationId: Int) async throws {
        try await client.requestVoid(path: "locations/\(locationId)", method: .delete)
        try? APICacheManager.shared.locationsStorage?.removeAll()
    }
    
    func getGroups(forceRefresh: Bool = false) async throws -> [OrganizationGroup] {
        if !forceRefresh {
            if let cached = try? APICacheManager.shared.groupsStorage?.object(forKey: "all_groups") {
                return cached
            }
        }
        
        let fetched: [OrganizationGroup] = try await client.request(path: "groups")
        try? APICacheManager.shared.groupsStorage?.setObject(fetched, forKey: "all_groups")
        return fetched
    }
    
    func getGroupDetails(groupId: String) async throws -> OrganizationGroup {
        return try await client.request(path: "groups/\(groupId)")
    }
    
    func createGroup(newGroup: CreateUpdateGroupRequest) async throws -> OrganizationGroup {
        let group: OrganizationGroup = try await client.request(path: "groups", method: .post, body: newGroup)
        try? APICacheManager.shared.groupsStorage?.removeObject(forKey: "all_groups")
        return group
    }
    
    func updateGroup(existingGroup: CreateUpdateGroupRequest, groupID: String) async throws -> OrganizationGroup {
        let group: OrganizationGroup = try await client.request(path: "groups/\(groupID)", method: .put, body: existingGroup)
        try? APICacheManager.shared.groupsStorage?.removeObject(forKey: "all_groups")
        return group
    }
    
    func deleteGroup(groupID: String) async throws {
        try await client.requestVoid(path: "groups/\(groupID)", method: .delete)
        try? APICacheManager.shared.groupsStorage?.removeObject(forKey: "all_groups")
    }
    
    func getRolesGroup() async throws -> [Role] {
        return try await client.request(path: "groups/roles")
    }
    
    func assignGroupRole(roleToAssign: AddRemoveRole, userID: String, groupID: String) async throws {
        try await client.requestVoid(path: "groups/\(groupID)/members/\(userID)/roles", method: .post, body: roleToAssign)
    }
    
    func removeGroupRole(roleToRemove: AddRemoveRole, userID: String, groupID: String) async throws {
        try await client.requestVoid(path: "groups/\(groupID)/members/\(userID)/roles", method: .delete, body: roleToRemove)
    }
}
