import Foundation
import SwiftUI

enum ActiveOrganizationsSheet: Identifiable {
    case createOrganization
    case editOrganization(Organization)
    
    var id: String {
        switch self {
        case .createOrganization:
            return "createOrg"
        case .editOrganization(let org):
            return "editOrg_\(org.id)"
        }
    }
}

@MainActor
class OrganizationsViewModel: ObservableObject {
    @AppStorage("useWizard") var useWizard: Bool = true
    @Published var showCreateItemView = false
    @Published var searchText: String = ""
    @Published var organizations: [Organization] = []
    @Published var activeSheet: ActiveOrganizationsSheet?
    @Published var selectedOrganizationToDelete: Organization?
    @Published var isLoading: Bool = false
    @Published var showUsersSheet: Bool = false
    @Published var showGroups: Bool = false
    @Published var selectedContextOrganization: Organization? = nil
    @Published var groups: [OrganizationGroup] = []

    private let orgService = OrganizationService()
    
    var filteredOrganizations: [Organization] {
        let lowercasedSearch = searchText.lowercased()

        let filtered = searchText.isEmpty
            ? organizations
            : organizations.filter { org in
                org.name.lowercased().contains(lowercasedSearch) ||
                org.description.lowercased().contains(lowercasedSearch) ||
                org.street.lowercased().contains(lowercasedSearch) ||
                org.city.lowercased().contains(lowercasedSearch) ||
                org.country.lowercased().contains(lowercasedSearch)
            }

        return filtered.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func getGroups(user: User) {
        self.groups = []
        let groupIDs = Set(
            user.permissionsFlatList
                .filter { $0.scopeType == "GROUP" }
                .compactMap { $0.scopeId }
        )
        
        Task {
            for groupID in groupIDs {
                await getGroup(groupID: groupID)
            }
        }
    }
    
    func getGroup(groupID: String) async {
        do {
            let responseGroup = try await orgService.getGroupDetails(groupId: groupID)
            if let index = self.groups.firstIndex(where: { $0.groupId == responseGroup.groupId }) {
                self.groups[index] = responseGroup
            } else {
                self.groups.append(responseGroup)
            }
        } catch {
            handleError(error)
        }
    }
    
    func getOrganizations(forceRefresh: Bool = false) {
        Task {
            isLoading = true
            do {
                self.organizations = try await orgService.getOrganizations(forceRefresh: forceRefresh)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func createOrganization(newOrganization: CreateUpdateOrganizationRequest) {
        Task {
            do {
                let createdOrganization = try await orgService.createOrganization(newOrganization: newOrganization)
                self.organizations.append(createdOrganization)
                self.activeSheet = nil
            } catch {
                handleError(error)
            }
        }
    }
    
    func updateOrganization(existingOrganization: CreateUpdateOrganizationRequest, organizationId: Int) {
        Task {
            do {
                let updatedOrganization = try await orgService.updateOrganization(existingOrganization: existingOrganization, organizationId: organizationId)
                if let index = self.organizations.firstIndex(where: { $0.id == updatedOrganization.id }) {
                    self.organizations[index] = updatedOrganization
                    self.activeSheet = nil
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func deleteOrganization(organizationId: Int) {
        Task {
            do {
                try await orgService.deleteOrganization(organizationId: organizationId)
                self.organizations.removeAll(where: { $0.id == organizationId })
                self.activeSheet = nil
            } catch {
                handleError(error)
            }
        }
    }
    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        print("error: \(message)")
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }
}
