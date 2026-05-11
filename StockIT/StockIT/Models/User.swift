import Foundation

struct User: Codable, Identifiable {
    var id: Int { Int(userId) ?? 0 }
    
    let userId: String
    let email: String
    var accountActive: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let address: String
    let birthDate: String
    let description: String
    var userRoles: [UserRole]
    let permissionsFlatList: [Permission]
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    let lastLoginAt: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case accountActive = "account_active"
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case address
        case birthDate = "birth_date"
        case description
        case userRoles = "user_roles"
        case permissionsFlatList = "permissions_flat_list"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
        case lastLoginAt = "last_login_at"
    }
}

struct UserRole: Codable {
    let roleName: String
    let roleDescription: String
    let scopeType: String
    let scopeId: String?
    let permissions: [RolePermission]
    
    enum CodingKeys: String, CodingKey {
        case roleName = "role_name"
        case roleDescription = "role_description"
        case scopeType = "scope_type"
        case scopeId = "scope_id"
        case permissions
    }
}

struct Role: Codable {
    let name: String
    let description: String
    let scopeType: String
    let permissions: [RolePermission]
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case scopeType = "scope_type"
        case permissions
    }
}

struct RolePermission: Codable {
    let name: String
    let scopeType: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case scopeType = "scope_type"
        case description
    }
}

struct Permission: Codable {
    let permissionName: String
    let scopeType: String
    let scopeId: String?
    let permissionDescription: String
    
    enum CodingKeys: String, CodingKey {
        case permissionName = "permission_name"
        case scopeType = "scope_type"
        case scopeId = "scope_id"
        case permissionDescription = "permission_description"
    }
}

struct CreateRoleRequest: Encodable {
    let name: String
    let scopeType: String
    let description: String
    let permissions: [[String: String]]
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userInfo: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userInfo = "user_info"
    }
}



struct CreateUserRequest: Codable {
    let email: String
    let password: String
    let address: String
    let description: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let birthDate: String
    
    enum CodingKeys: String, CodingKey {
        case email, password, address, description
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case birthDate = "birth_date"
    }
}

struct UpdateUserRequest: Codable {
    let email: String
    let address: String
    let description: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let birthDate: String
    
    enum CodingKeys: String, CodingKey {
        case email, address, description
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case birthDate = "birth_date"
    }
}

struct ChangePasswordRequest: Codable{
    let oldPassword: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case oldPassword = "old_password"
        case newPassword = "new_password"
    }
}

struct AddRemoveRole: Codable{
    let roleName: String
    let scopeType: String
    let scopeID: String
    
    enum CodingKeys: String, CodingKey {
        case roleName = "role_name"
        case scopeType = "scope_type"
        case scopeID = "scope_id"
    }
}

struct LoginRequestBody: Codable {
    let email: String
    let password: String
}
