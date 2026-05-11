import Foundation
import SwiftUI

@MainActor
class AccountViewModel: ObservableObject {
    @AppStorage("useWizard") var useWizard: Bool = true
    @AppStorage("useAI") var useAI: Bool = true
    
    @Published var isEditing = false
    @Published var email: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var address: String = ""
    @Published var description: String = ""
    
    @Published var scopeNames: [String: String] = [:]
    @Published var showDeleteRoleAlert: Bool = false
    @Published var contextMenuRoleName: String? = nil
    
    @Published var allRoles: [Role] = []
    @Published var allPermissions: [RolePermission] = []
    @Published var roleToEdit: Role? = nil
    
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var showCreateUpdateRoleSheet: Bool = false
    @Published var selectedPermissions: Set<String> = ["VIEW_ATTRIBUTES", "VIEW_CATEGORIES"]
    @Published var roleName: String = ""
    @Published var roleDescription: String = ""
    @Published var roleScopeType: String = "GLOBAL" {
        didSet {
            selectedPermissions = []
            switch roleScopeType {
            case "GLOBAL":
                selectedPermissions.insert("VIEW_ATTRIBUTES")
                selectedPermissions.insert("VIEW_CATEGORIES")
            case "ORGANIZATION":
                selectedPermissions.insert("VIEW_ORGANIZATION")
            case "GROUP":
                selectedPermissions.insert("VIEW_GROUP")
            case "LOCATION":
                selectedPermissions.insert("VIEW_LOCATION")
                selectedPermissions.insert("VIEW_ITEM")
            default: break
            }
        }
    }
    
    private let userService = UserService()
    private let authService = AuthService()
    private let orgService = OrganizationService()

    var canSubmitEditRole: Bool {
        guard let roleToEdit = roleToEdit else { return false }
        let originalPermissions = Set(roleToEdit.permissions.compactMap { $0.name })
        let nameChanged = roleToEdit.name != roleName
        let descriptionChanged = roleToEdit.description != roleDescription
        let scopeChanged = roleToEdit.scopeType != roleScopeType
        let permissionsChanged = originalPermissions != selectedPermissions
        return (nameChanged || descriptionChanged || scopeChanged || permissionsChanged) && canSubmitRole
    }
    
    var canSubmitRole: Bool {
        !roleName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !roleDescription.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPermissions.isEmpty
    }
    
    var filteredPermissions: [RolePermission] {
        allPermissions.filter { $0.scopeType == roleScopeType }
    }
    
    var lengthValid: Bool { newPassword.count >= 10 && newPassword.count <= 50 }
    var containsLowercase: Bool { newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil }
    var containsUppercase: Bool { newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil }
    var containsDigit: Bool { newPassword.rangeOfCharacter(from: .decimalDigits) != nil }
    var containsSpecialChar: Bool { newPassword.rangeOfCharacter(from: CharacterSet.letters.union(.decimalDigits).inverted) != nil }
    var isPasswordValid: Bool {
        lengthValid && containsLowercase && containsUppercase && containsDigit && containsSpecialChar &&
        newPassword == confirmPassword && !newPassword.isEmpty && !currentPassword.isEmpty &&
        newPassword != currentPassword
    }
    
    let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()
    
    let backendDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var birthDateFormatted: String { backendDateFormatter.string(from: birthDate) }
    
    @Published var isCurrentPasswordVisible = false
    @Published var isNewPasswordVisible = false
    @Published var isConfirmPasswordVisible = false
    @Published var birthDate = Date()
    @Published var birthDateString = ""
    @Published var isValidDate = true
    
    func logout() {
            let storage = SecureStorage()
            storage.delete("AccessToken")
            storage.delete("RefreshToken")
        }

    func loadData(from user: User) {
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        phone = user.phoneNumber
        address = user.address
        description = user.description
        
        if let parsedDate = backendDateFormatter.date(from: user.birthDate) {
            birthDate = parsedDate
            birthDateString = dateFormatter.string(from: parsedDate)
            isValidDate = true
        } else {
            birthDate = Date()
            birthDateString = ""
            isValidDate = false
        }
    }

    func formatInput() {
        let digits = birthDateString.filter { $0.isNumber }
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 2 || index == 4 { result.append("/") }
            if index < 8 { result.append(char) }
        }
        birthDateString = result
        if result.count == 10, let parsedDate = dateFormatter.date(from: result), isDateValid(parsedDate) {
            birthDate = parsedDate
            isValidDate = true
        } else {
            isValidDate = false
        }
    }
    
    func isDateValid(_ date: Date) -> Bool {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0 >= 16
    }


    func updateUser(userID: String) {
        Task {
            let request = UpdateUserRequest(
                email: email, address: address, description: description,
                firstName: firstName, lastName: lastName, phoneNumber: phone,
                birthDate: birthDateFormatted
            )
            do {
                let updated = try await userService.updateUser(updatedUser: request, userID: userID)
                UserSession.shared.mainUser = updated
                self.isEditing = false
            } catch {
                handleError(error)
            }
        }
    }

    func changePassword(userID: String) {
        Task {
            let request = ChangePasswordRequest(oldPassword: currentPassword, newPassword: newPassword)
            do {
                try await userService.changePassword(changePassword: request, userID: userID)
                self.currentPassword = ""
                self.newPassword = ""
                self.confirmPassword = ""
            } catch {
                handleError(error)
            }
        }
    }

    func getScopeName(scopeType: String, scopeId: String) {
        let key = "\(scopeType)-\(scopeId)"
        guard scopeNames[key] == nil else { return }
        
        Task {
            do {
                let name: String
                switch scopeType.uppercased() {
                case "LOCATION":
                    name = try await orgService.getLocationDetails(locationId: scopeId).name
                case "ORGANIZATION":
                    name = try await orgService.getOrganizationDetails(organizationId: scopeId).name
                case "GROUP":
                    name = try await orgService.getGroupDetails(groupId: scopeId).name
                default:
                    name = scopeId
                }
                self.scopeNames[key] = name
            } catch {
                self.scopeNames[key] = "Unknown \(scopeType)"
            }
        }
    }

    func fetchData() {
        Task {
            async let roles = authService.getAllRoles()
            async let perms = authService.getAllPermissions()
            do {
                self.allRoles = try await roles
                let fetchedPerms = try await perms
                self.allPermissions = fetchedPerms.filter { $0.name != "EVERYTHING" }
            } catch {
                handleError(error)
            }
        }
    }

    func createRole() {
        Task {
            let perms = selectedPermissions.map { [$0: roleScopeType] }
            let request = CreateRoleRequest(name: roleName, scopeType: roleScopeType, description: roleDescription, permissions: perms)
            do {
                let newRole = try await authService.createRole(newRole: request)
                self.allRoles.append(newRole)
                self.showCreateUpdateRoleSheet = false
            } catch {
                handleError(error)
            }
        }
    }

    func updateRole(roleToEditName: String) {
        Task {
            let perms = selectedPermissions.map { [$0: roleScopeType] }
            let request = CreateRoleRequest(name: roleName, scopeType: roleScopeType, description: roleDescription, permissions: perms)
            do {
                let updated = try await authService.updateRole(updatedRole: request, roleName: roleToEditName)
                if let index = allRoles.firstIndex(where: { $0.name == roleToEditName }) {
                    allRoles[index] = updated
                }
                self.showCreateUpdateRoleSheet = false
            } catch {
                handleError(error)
            }
        }
    }

    func deleteRole(roleName: String) {
        Task {
            do {
                try await authService.deleteRole(roleName: roleName)
                self.allRoles.removeAll { $0.name == roleName }
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
    func passwordRuleText(_ text: String, fulfilled: Bool) -> some View {
        Text("• \(text)").font(.caption).foregroundStyle(fulfilled ? .green : .red)
    }
    
    func labeledField(_ label: String, text: Binding<String>, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(label).foregroundStyle(.gray)
                if required {
                    Text("*").foregroundStyle(.red)
                }
            }
            TextField("", text: text)
        }
    }
}
