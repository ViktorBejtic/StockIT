import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var showPassword: Bool = false
    @Published var isLoading: Bool = false
    
    @Published var isAuthenticated: Bool = false
    
    private let authService = AuthService()

    var isSignInButtonDisabled: Bool {
        email.isEmpty || password.isEmpty || isLoading
    }
    
    func login() {
        Task {
            isLoading = true
            do {
                let responseData = try await authService.login(email: email, password: password)
                UserSession.shared.mainUser = responseData.userInfo
                self.isAuthenticated = true
                
                print("login: \(responseData.userInfo.firstName)")
                
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        print("login failed: \(message)")
        
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }
}
