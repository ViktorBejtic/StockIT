import Foundation
import Alamofire
import KeychainAccess

class SecureStorage {
    private let keychain = Keychain(service: "sk.stuba.stockit")
    
    func save(_ value: String, for key: String) {
        do {
            try keychain.set(value, key: key)
        } catch {
            print("keychain save error: \(error)")
        }
    }
    
    func get(_ key: String) -> String? {
        return try? keychain.get(key)
    }
    
    func delete(_ key: String) {
        try? keychain.remove(key)
    }
}

class AuthService {
    private let client = NetworkClient.shared
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequestBody(email: email.lowercased() + "@stockit.sk", password: password)
        let response: AuthResponse = try await client.request(path: "auth/login", method: .post, body: body, publicEndpoint: true)

        client.storage.save(response.accessToken, for: "AccessToken")
        client.storage.save(response.refreshToken, for: "RefreshToken")
        return response
    }
    
    func refreshToken() async throws -> AuthResponse {
        guard let refreshToken = client.storage.get("RefreshToken") else {
            throw ErrorResponse.custom("No refresh token found")
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(refreshToken)",
            "Content-Type": "application/json"
        ]
        
        let url = client.startURL + "auth/refresh"
        
        let response = await AF.request(url, method: .get, headers: headers)
            .validate(statusCode: 200...299)
            .serializingData()
            .response
        
        let data: AuthResponse = try client.handleResponseData(response)

        client.storage.save(data.accessToken, for: "AccessToken")
        client.storage.save(data.refreshToken, for: "RefreshToken")
        
        return data
    }
    
    func getAllRoles() async throws -> [Role] {
        return try await client.request(path: "auth/roles")
    }
    
    func createRole(newRole: CreateRoleRequest) async throws -> Role {
        return try await client.request(path: "auth/roles", method: .post, body: newRole)
    }
    
    func updateRole(updatedRole: CreateRoleRequest, roleName: String) async throws -> Role {
        return try await client.request(path: "auth/roles/\(roleName)", method: .put, body: updatedRole)
    }
    
    func deleteRole(roleName: String) async throws {
        try await client.requestVoid(path: "auth/roles/\(roleName)", method: .delete)
    }
    
    func getAllPermissions() async throws -> [RolePermission] {
        return try await client.request(path: "auth/permissions")
    }
}

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    let storage = SecureStorage()
    
    private let lock = NSLock()
    private var _isRefreshing = false
    
    private var isRefreshing: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isRefreshing
        }
        set {
            lock.lock()
            _isRefreshing = newValue
            lock.unlock()
        }
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        
        if let token = storage.get("AccessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }

        guard !isRefreshing else {
            completion(.doNotRetry)
            return
        }
        
        isRefreshing = true
        print("token expired, refreshing")

        Task {
            do {
                let authService = AuthService()
                let _ = try await authService.refreshToken()
                
                print("token refreshed")
                self.isRefreshing = false
                completion(.retry)
                
            } catch {
                print("refresh failed")
                self.isRefreshing = false
                completion(.doNotRetryWithError(error))
                
                await MainActor.run {
                    UserSession.shared.logout()
                }
            }
        }
    }
}
