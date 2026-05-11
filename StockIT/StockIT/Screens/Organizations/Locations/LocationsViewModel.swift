import Foundation
import SwiftUI

enum ActiveLocationSheet: Identifiable {
    case create
    case edit(Location)
    
    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let location):
            return "edit-\(location.id)"
        }
    }
}

@MainActor
class LocationsViewModel: ObservableObject {
    @AppStorage("useWizard") var useWizard: Bool = true
    @Published var showCreateItemView = false
    @Published var searchText: String = ""
    @Published var locations: [Location] = []
    @Published var activeSheet: ActiveLocationSheet?
    @Published var selectedLocationToDelete: Location?
    @Published var isLoading: Bool = false
    @Published var showUsersSheet: Bool = false
    @Published var showGroupsSheet: Bool = false

    private let orgService = OrganizationService()
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var totalItemsCount: Int {
        locations.reduce(0) { $0 + (Int($1.itemCount) ?? 0) }
    }

    var allItemsLocation: Location {
        Location(
            locationId: "-1",
            organizationId: locations.first?.organizationId ?? "-1",
            name: "Všetky položky",
            room: nil,
            description: "Všetky položky uložené v tejto organizácii.",
            itemCount: "\(totalItemsCount)",
            createdBy: "-1",
            createdAt: "",
            lastEditBy: nil,
            lastEditAt: nil
        )
    }

    
    var filteredLocations: [Location] {
        let search = searchText.lowercased()
        
        var filtered = locations
        
        if search.isEmpty {
            filtered = filtered.sorted { $0.name < $1.name }
            
            if filtered.count > 1 && !filtered.contains(where: { $0.id == -1 }) {
                filtered.insert(allItemsLocation, at: 0)
            }
            return filtered
        }
        
        if filtered.count > 1 && !filtered.contains(where: { $0.id == -1 }) {
            filtered.insert(allItemsLocation, at: 0)
        }

        filtered = locations.filter {
            $0.name.lowercased().contains(search) ||
            $0.description.lowercased().contains(search) ||
            ($0.room?.lowercased().contains(search) ?? false) ||
            $0.itemCount.contains(search)
        }

        filtered = filtered.sorted { $0.name < $1.name }
    
        if let index = filtered.firstIndex(where: { $0.id == -1 }) {
            let allItems = filtered.remove(at: index)
            filtered.insert(allItems, at: 0)
        }
        
        return filtered
    }
    
    
    func getLocations(organizationId: Int, forceRefresh: Bool = false) {
        Task {
            isLoading = true
            do {
                self.locations = try await orgService.getLocations(organizationId: organizationId, forceRefresh: forceRefresh)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func createLocation(newLocation: CreateUpdateLocationRequest) {
        Task {
            do {
                let createdLocation = try await orgService.createLocation(newLocation: newLocation)
                self.locations.append(createdLocation)
                self.activeSheet = nil
            } catch {
                handleError(error)
            }
        }
    }
    
    func updateLocation(existingLocation: CreateUpdateLocationRequest, locationId: Int) {
        Task {
            do {
                let updatedLocation = try await orgService.updateLocation(existingLocation: existingLocation, locationId: locationId)
                if let index = self.locations.firstIndex(where: { $0.id == updatedLocation.id }) {
                    self.locations[index] = updatedLocation
                    self.activeSheet = nil
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func deleteLocation(locationId: Int) {
        Task {
            do {
                try await orgService.deleteLocation(locationId: locationId)
                self.locations.removeAll(where: { $0.id == locationId })
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
