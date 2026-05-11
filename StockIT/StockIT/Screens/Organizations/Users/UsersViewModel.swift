import Foundation
import SwiftUI

enum AlertType {
    case deleteUser
    case disableUser
    case enableUser
    
    var buttonLabel: String {
        switch self {
        case .deleteUser: return "deleteButton".localized
        case .disableUser: return "disableButton".localized
        case .enableUser: return "enableButton".localized
        }
    }

    var alertTitle: String {
        switch self {
        case .deleteUser: return "deleteUserButton".localized
        case .disableUser: return "disableAccountButton".localized
        case .enableUser: return "enableAccountButton".localized
        }
    }
}

@MainActor
class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var showCreateUser: Bool = false
    @Published var editingUser: User? = nil
    @Published var scopeNames: [String: String] = [:]
    
    @Published var contextMenuUserIndex: Int? = nil
    @Published var showEditUser: Bool = false
    @Published var showEditingUser: Bool = false
    
    @Published var showAlert: Bool = false
    @Published var showUserDetailsAlert: Bool = false
    
    @Published var alertType: AlertType? = nil
    @Published var alertMessage: String = ""
    @Published var showResetPassword: Bool = false
    @Published var showUserDetailsResetPassword: Bool = false
    @Published var userDeleted: Bool = false
    @Published var showPassword: Bool = false
    @Published var newPassword: String = ""
    
    @Published var showAssignRole: Bool = false
    
    @Published var email: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phonePrefix: String = "421"
    @Published var phoneNumber: String = ""
    @Published var description: String = ""
    @Published var street: String = ""
    @Published var streetNumber: String = ""
    @Published var city: String = ""
    @Published var postalCode: String = ""
    @Published var country: String = ""
    @Published var showCopiedAlert = false
    @Published var birthDate: Date = Date()
    @Published var birthDateString: String = ""
    @Published var isValidDate: Bool = true
    @Published var showRemoveRoleAlert: Bool = false
    
    @Published var address: String = ""
    @Published var searchText: String = ""
    @Published var roleToRemove: AddRemoveRole? = nil
    
    @Published var allRoles: [Role] = []
    @Published var organizations: [Organization] = []
    @Published var locations: [Location] = []
    @Published var groups: [OrganizationGroup] = []

    var organizationFilter: String? = nil
    
    private let userService = UserService()
    private let authService = AuthService()
    private let orgService = OrganizationService()
    
    
    var filteredUsers: [User] {
        var base = users

        if let orgId = organizationFilter {
            base = base.filter { user in
                user.permissionsFlatList.contains(where: {
                    ($0.scopeType == "ORGANIZATION" && $0.scopeId == orgId) ||
                    $0.permissionName == "EVERYTHING"
                })
            }
        }

        let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return base.sorted { $0.firstName < $1.firstName } }

        let filtered = base.filter {
            $0.email.lowercased().contains(search) ||
            $0.address.lowercased().contains(search) ||
            $0.description.lowercased().contains(search) ||
            $0.firstName.lowercased().contains(search) ||
            $0.lastName.lowercased().contains(search) ||
            $0.phoneNumber.lowercased().contains(search) ||
            $0.birthDate.lowercased().contains(search)
        }
        return filtered.sorted { $0.firstName < $1.firstName }
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    let backendDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var birthDateFormatted: String { backendDateFormatter.string(from: birthDate) }
    var fullAddress: String { "\(street) \(streetNumber), \(city), \(postalCode), \(country)" }
    
    var canSubmit: Bool {
        !email.isEmpty && !firstName.isEmpty && !lastName.isEmpty &&
        !phoneNumber.isEmpty && !street.isEmpty && !streetNumber.isEmpty &&
        !city.isEmpty && !postalCode.isEmpty && !country.isEmpty &&
        !description.isEmpty && isValidDate && isPasswordValid
    }
    
    
    func resetForm() {
        email = ""; newPassword = ""; firstName = ""; lastName = ""
        phonePrefix = "421"; phoneNumber = ""; description = ""
        street = ""; streetNumber = ""; city = ""; postalCode = ""; country = ""
        showPassword = false; showCopiedAlert = false
        birthDate = Date(); birthDateString = ""; isValidDate = true
    }
    
    func fillForm(user: User) {
        firstName = user.firstName; lastName = user.lastName
        email = user.email; phoneNumber = user.phoneNumber
        address = user.address; description = user.description
        
        if let parsedDate = backendDateFormatter.date(from: user.birthDate) {
            birthDate = parsedDate; birthDateString = dateFormatter.string(from: parsedDate)
            isValidDate = true
        } else {
            birthDate = Date(); birthDateString = ""
            isValidDate = false
        }
    }
    
    func generatePassword(length: Int = 12) -> String {
        precondition(length >= 10, "Password length must be at least 10.")
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let digits = "0123456789"
        let special = "!@#$%^&*()"
        let allCharacters = lowercase + uppercase + digits + special
        
        var password = ""
        password.append(lowercase.randomElement()!)
        password.append(uppercase.randomElement()!)
        password.append(digits.randomElement()!)
        password.append(special.randomElement()!)
        
        let remainingLength = length - password.count
        password += String((0..<remainingLength).compactMap { _ in allCharacters.randomElement() })
        return String(password.shuffled())
    }
    
    var lengthValid: Bool { newPassword.count >= 10 && newPassword.count <= 50 }
    var containsLowercase: Bool { newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil }
    var containsUppercase: Bool { newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil }
    var containsDigit: Bool { newPassword.rangeOfCharacter(from: .decimalDigits) != nil }
    var containsSpecialChar: Bool { newPassword.rangeOfCharacter(from: CharacterSet.letters.union(.decimalDigits).inverted) != nil }
    var isPasswordValid: Bool { lengthValid && containsLowercase && containsUppercase && containsDigit && containsSpecialChar }
    
    func formatInput() {
        let digits = birthDateString.filter { $0.isNumber }
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 2 || index == 4 { result.append("/") }
            if index < 8 { result.append(char) }
        }
        birthDateString = result
        if result.count == 10, let parsedDate = dateFormatter.date(from: result), isDateValid(parsedDate) {
            birthDate = parsedDate; isValidDate = true
        } else {
            isValidDate = false
        }
    }
    
    func isDateValid(_ date: Date) -> Bool {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0 >= 16
    }
    
    
    func getUsers(forceRefresh: Bool = false) {
        Task {
            do { self.users = try await userService.getUsers(forceRefresh: forceRefresh) }
            catch { handleError(error) }
        }
    }
    
    func createUser() {
        Task {
            let newUser = CreateUserRequest(
                email: email, password: newPassword, address: fullAddress, description: description,
                firstName: firstName, lastName: lastName, phoneNumber: "+\(phonePrefix)\(phoneNumber)",
                birthDate: birthDateFormatted
            )
            do {
                let createdUser = try await userService.createUser(newUser: newUser)
                self.users.append(createdUser)
                self.showCreateUser = false
            } catch { handleError(error) }
        }
    }
    
    func updateUser(user: Binding<User>) {
        Task {
            let existingUser = UpdateUserRequest(
                email: email, address: address, description: description,
                firstName: firstName, lastName: lastName, phoneNumber: phoneNumber,
                birthDate: birthDateFormatted
            )
            do {
                let updatedUser = try await userService.updateUser(updatedUser: existingUser, userID: user.wrappedValue.userId)
                user.wrappedValue = updatedUser
                self.showEditUser = false
                self.showEditingUser = false
            } catch { handleError(error) }
        }
    }
    
    func deleteUser(userID: String) {
        Task {
            do {
                try await userService.deleteUser(userID: userID)
                self.users.removeAll { $0.userId == userID }
                self.userDeleted = true
            } catch { handleError(error) }
        }
    }
    
    func disableUser(user: Binding<User>) {
        Task {
            do {
                try await userService.disableUser(userID: user.wrappedValue.userId)
                user.wrappedValue.accountActive = "false"
            } catch { handleError(error) }
        }
    }
    
    func enableUser(user: Binding<User>) {
        Task {
            do {
                try await userService.enableUser(userID: user.wrappedValue.userId)
                user.wrappedValue.accountActive = "true"
            } catch { handleError(error) }
        }
    }
    
    func resetPassword(userID: String) {
        Task {
            do {
                let request = ChangePasswordRequest(oldPassword: "", newPassword: newPassword)
                try await userService.changePassword(changePassword: request, userID: userID)
                self.showResetPassword = false
            } catch { handleError(error) }
        }
    }
    
    
    func removeRole(roleToRemove: AddRemoveRole, user: Binding<User>) {
        Task {
            do {
                try await userService.removeRole(roleToRemove: roleToRemove, userID: user.wrappedValue.userId)
                user.wrappedValue.userRoles.removeAll {
                    $0.roleName == roleToRemove.roleName &&
                    $0.scopeType == roleToRemove.scopeType &&
                    $0.scopeId == roleToRemove.scopeID
                }
            } catch { handleError(error) }
        }
    }
    
    func assignRole(roleToAssign: Role, scopeID: String, user: Binding<User>) {
        Task {
            let roleToAdd = AddRemoveRole(roleName: roleToAssign.name, scopeType: roleToAssign.scopeType, scopeID: scopeID)
            do {
                try await userService.assignRole(roleToAssign: roleToAdd, userID: user.wrappedValue.userId)
                let newUserRole = UserRole(
                    roleName: roleToAssign.name, roleDescription: roleToAssign.description,
                    scopeType: roleToAssign.scopeType, scopeId: scopeID, permissions: roleToAssign.permissions
                )
                user.wrappedValue.userRoles.append(newUserRole)
                self.showAssignRole = false
            } catch { handleError(error) }
        }
    }
    
    func getAllRoles(user: User) {
        Task {
            do {
                var roles = try await authService.getAllRoles()
                roles.removeAll { $0.name.lowercased() == "superadmin" }
                if !user.permissionsFlatList.contains(where: {$0.permissionName == "EVERYTHING"}) {
                    roles.removeAll { role in
                        role.scopeType == "GLOBAL" || (role.scopeType == "ORGANIZATION" && role.name.lowercased().contains("admin"))
                    }
                }
                self.allRoles = roles
            } catch { handleError(error) }
        }
    }
    
    
    func getOrganizations(user: User) {
        self.organizations = []
        self.groups = []
        
        Task {
            let hasEverything = user.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" })
            let hasManageGroup = user.permissionsFlatList.contains(where: { $0.permissionName == "MANAGE_GROUP" })
            
            if hasEverything || hasManageGroup {
                await fetchGroups()
            }
            
            if hasEverything {
                do {
                    let orgs = try await orgService.getOrganizations()
                    self.organizations = orgs
                    self.locations = []
                    for org in orgs { await fetchLocations(for: org.id) }
                } catch { handleError(error) }
                
            } else {
                let matchingPermissions = user.permissionsFlatList.filter {
                    $0.scopeType.uppercased() == "ORGANIZATION" && $0.permissionName.uppercased() == "MANAGE_ROLES"
                }
                
                var fetchedOrganizations: [Organization] = []
                
                await withTaskGroup(of: Organization?.self) { taskGroup in
                    for perm in matchingPermissions {
                        guard let orgId = perm.scopeId else { continue }
                        taskGroup.addTask {
                            return try? await self.orgService.getOrganizationDetails(organizationId: orgId)
                        }
                    }
                    
                    for await org in taskGroup {
                        if let org = org, !fetchedOrganizations.contains(where: { $0.id == org.id }) {
                            fetchedOrganizations.append(org)
                        }
                    }
                }
                
                self.organizations = fetchedOrganizations
                self.locations = []
                for org in self.organizations { await fetchLocations(for: org.id) }
            }
        }
    }
    
    private func fetchGroups() async {
        do { self.groups = try await orgService.getGroups() }
        catch { handleError(error) }
    }
    
    private func fetchLocations(for orgId: Int) async {
        do {
            let locs = try await orgService.getLocations(organizationId: orgId)
            self.locations.append(contentsOf: locs)
        } catch { print("locs failed \(orgId): \(error.localizedDescription)") }
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
                self.scopeNames[key] = "Unknown"
            }
        }
    }
    
    func getLocationName(locationId: String, completion: @escaping (String) -> Void) {
        Task {
            do { completion(try await orgService.getLocationDetails(locationId: locationId).name) }
            catch { completion("Unknown") }
        }
    }
    func getOrganizationName(organizationId: String, completion: @escaping (String) -> Void) {
        Task {
            do { completion(try await orgService.getOrganizationDetails(organizationId: organizationId).name) }
            catch { completion("Unknown") }
        }
    }
    func getGroupName(groupId: String, completion: @escaping (String) -> Void) {
        Task {
            do { completion(try await orgService.getGroupDetails(groupId: groupId).name) }
            catch { completion("Unknown") }
        }
    }
    
    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        print("error: \(message)")
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }
    
    
    @ViewBuilder
    func passwordRuleText(_ text: String, fulfilled: Bool) -> some View {
        Text("• \(text)")
            .font(.caption)
            .foregroundStyle(fulfilled ? .green : .red)
    }
    
    @ViewBuilder
    func labeledField(_ label: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(label).foregroundStyle(.gray)
                Text("*").foregroundStyle(.red)
            }
            if isSecure {
                SecureField("", text: text)
            } else {
                TextField("", text: text)
            }
        }
    }
}
