import Foundation
import SwiftUI

@MainActor
class UserSession: ObservableObject {
    @Published var mainUser: User?
    @Published var isRestoring: Bool = true
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    static let shared = UserSession()
    private let authService = AuthService()
    private let storage = SecureStorage()
    
    private init() {}
    
    func restoreSession() {
        Task {
            isRestoring = true
            
            guard storage.get("RefreshToken") != nil else {
                self.mainUser = nil
                self.isRestoring = false
                return
            }
            
            do {
                let response = try await authService.refreshToken()
                self.mainUser = response.userInfo
                print("session restored: \(response.userInfo.firstName)")
            } catch {
                print("session restore failed: \(error.localizedDescription)")
                self.logout()
            }
            
            self.isRestoring = false
        }
    }
    
    func logout() {
        storage.delete("AccessToken")
        storage.delete("RefreshToken")
        APICacheManager.shared.clearAll()
        self.mainUser = nil
    }
}
