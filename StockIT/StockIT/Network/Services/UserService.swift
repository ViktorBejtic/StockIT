import Foundation

class UserService {
    private let client = NetworkClient.shared
    
    func getUsers(forceRefresh: Bool = false) async throws -> [User] {
        if !forceRefresh {
            if let cached = try? APICacheManager.shared.usersStorage?.object(forKey: "all_users") {
                return cached
            }
        }
        
        let fetched: [User] = try await client.request(path: "users")
        
        try? APICacheManager.shared.usersStorage?.setObject(fetched, forKey: "all_users")
        
        return fetched
    }
    
    func createUser(newUser: CreateUserRequest) async throws -> User {
        let user: User = try await client.request(path: "users", method: .post, body: newUser)
        try? APICacheManager.shared.usersStorage?.removeObject(forKey: "all_users")
        return user
    }
    
    func getUserDetails(userID: String) async throws -> User {
        return try await client.request(path: "users/\(userID)")
    }
    
    func updateUser(updatedUser: UpdateUserRequest, userID: String) async throws -> User {
        let user: User = try await client.request(path: "users/\(userID)", method: .put, body: updatedUser)
        try? APICacheManager.shared.usersStorage?.removeObject(forKey: "all_users")
        return user
    }
    
    func deleteUser(userID: String) async throws {
        try await client.requestVoid(path: "users/\(userID)", method: .delete)
        try? APICacheManager.shared.usersStorage?.removeObject(forKey: "all_users")
    }
    
    func changePassword(changePassword: ChangePasswordRequest, userID: String) async throws {
        try await client.requestVoid(path: "users/\(userID)/change-password", method: .put, body: changePassword)
    }
    
    func resetPassword(newPassword: String, userID: String) async throws {
        try await client.requestVoid(path: "users/\(userID)/reset-password", method: .put, body: newPassword)
    }
    
    func disableUser(userID: String) async throws {
        try await client.requestVoid(path: "users/\(userID)/disable-account", method: .patch)
        try? APICacheManager.shared.usersStorage?.removeObject(forKey: "all_users")
    }
    
    func enableUser(userID: String) async throws {
        try await client.requestVoid(path: "users/\(userID)/enable-account", method: .patch)
        try? APICacheManager.shared.usersStorage?.removeObject(forKey: "all_users")
    }
    
    func assignRole(roleToAssign: AddRemoveRole, userID: String) async throws {
        try await client.requestVoid(path: "users/\(userID)/roles/assign", method: .post, body: roleToAssign)
        try? APICacheManager.shared.usersStorage?.removeObject(forKey: "all_users")
    }
    
    func removeRole(roleToRemove: AddRemoveRole, userID: String) async throws {
        try await client.requestVoid(path: "users/\(userID)/roles/remove", method: .delete, body: roleToRemove)
        try? APICacheManager.shared.usersStorage?.removeObject(forKey: "all_users")
    }

    func resolveUserName(userId: String) async -> String {
        if let cached = try? APICacheManager.shared.usersStorage?.object(forKey: "all_users"),
           let user = cached.first(where: { $0.userId == userId }) {
            if user.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) {
                return "Super Admin"
            }
            return "\(user.firstName) \(user.lastName)"
        }

        if let user = try? await getUserDetails(userID: userId) {
            if user.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) {
                return "Super Admin"
            }
            return "\(user.firstName) \(user.lastName)"
        }

        return userId
    }
}
