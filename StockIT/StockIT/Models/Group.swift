import Foundation

struct OrganizationGroup: Codable, Identifiable {
    var id: Int { Int(groupId) ?? -1 }
    
    let groupId: String
    let organizationId: String
    let name: String
    let description: String
    let assignedLocations: [GroupLocation]
    let tenant: GroupUser?
    let members: [GroupUser]?
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case organizationId = "organization_id"
        case name
        case description
        case assignedLocations = "assigned_locations"
        case tenant
        case members
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}

struct GroupUser: Codable, Identifiable {
    var id: Int { Int(userId) ?? -1 }
    
    let userId: String
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case description
    }
}

struct GroupLocation: Codable, Identifiable {
    var id: Int {
        return Int(locationId) ?? -1
    }
    
    let locationId: String
    let organizationId: String
    let name: String
    let room: String?
    let description: String
    let itemCount: String?
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    
    enum CodingKeys: String, CodingKey {
        case locationId = "location_id"
        case name = "location_name"
        case room
        case description
        case organizationId = "organization_id"
        case itemCount = "item_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}

struct CreateUpdateGroupRequest: Codable {
    let name: String
    let description: String
    let organizationID: String
    let locations: [String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case organizationID = "organization_id"
        case locations = "locations_to_assign"
    }
}
