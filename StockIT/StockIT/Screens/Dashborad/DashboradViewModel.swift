import Foundation
import CoreLocation
import MapKit
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var mapPosition: MapCameraPosition = .automatic
    @Published var activeID: String?
    
    @AppStorage("DashboardSelectedOrganizationID") var selectedOrganizationID: Int = 0
    
    @Published var organizations: [Organization] = []
    @Published var locations: [Location] = []
    @Published var items: [Item] = []
    @Published var isLoadingMore: Bool = false
    @Published var metadata: Metadata = .default
    @Published var selectedLocationId: Int? = nil
    @Published var shouldRefresh: Bool = false
    @Published var selectedItem: Item? = nil
    @Published var isLoadingItems: Bool = false
    @Published var isLoadingLocations: Bool = false

    private let itemService = ItemService()
    private let orgService = OrganizationService()
    
    var nextPage: Int = Metadata.default.page
    
    var selectedOrganization: Organization? {
        organizations.first { $0.id == selectedOrganizationID }
    }
    
    var totalItems: Int {
        locations.reduce(0) { $0 + (Int($1.itemCount) ?? 0) }
    }
    
    
    func getData(organizationId: Int, forceRefresh: Bool = false) {
        Task {
            nextPage = 0
            isLoadingItems = true
            isLoadingLocations = true
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.getLocations(organizationId: organizationId, forceRefresh: forceRefresh) }
                group.addTask { await self.getItems(organizationId: organizationId) }
            }
            
            if let org = selectedOrganization {
                updateCoordinate(for: org)
            }
        }
    }
    
    func refreshFilteredItems() {
        items.removeAll { $0.archived == "deleted" || $0.archived == "true" }
        items.removeAll { $0.organizationId != String(selectedOrganizationID) }
    }
    
    
    func getOrganizations(forceRefresh: Bool = false) {
        Task {
            do {
                let responseOrganizations = try await orgService.getOrganizations(forceRefresh: forceRefresh)
                self.organizations = responseOrganizations
                
                if self.selectedOrganizationID == 0 {
                    self.selectedOrganizationID = responseOrganizations.first?.id ?? 0
                } else if !responseOrganizations.contains(where: { $0.id == self.selectedOrganizationID }) {
                    self.selectedOrganizationID = responseOrganizations.first?.id ?? 0
                }
                
                self.getData(organizationId: self.selectedOrganizationID, forceRefresh: forceRefresh)
            } catch {
                handleError(error)
            }
        }
    }
    
    func getLocations(organizationId: Int, forceRefresh: Bool = false) async {
        do {
            let responseLocations = try await orgService.getLocations(organizationId: organizationId, forceRefresh: forceRefresh)
            self.locations = responseLocations
            self.isLoadingLocations = false
        } catch {
            print("locs error: \(error.localizedDescription)")
            if let orgID = self.organizations.first?.id, orgID != 0, orgID != organizationId {
                await self.getLocations(organizationId: orgID, forceRefresh: forceRefresh)
            }
            self.isLoadingLocations = false
        }
    }
    
    func getItems(organizationId: Int) async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        do {
            let responseItems = try await itemService.getItems(
                organizations: [organizationId],
                locations: [],
                itemName: "",
                categories: [],
                attributes: [],
                statuses: [],
                archived: false,
                page: nextPage,
                size: metadata.size,
                sort: "created_at:desc"
            )
            
            if responseItems.metadata.first {
                self.items = responseItems.data
            } else {
                self.items.append(contentsOf: responseItems.data)
            }
            
            self.metadata = responseItems.metadata
            self.nextPage = responseItems.metadata.page + 1
            self.isLoadingItems = false
        } catch {
            handleError(error)
            self.isLoadingItems = false
        }
        self.isLoadingMore = false
    }
    
    func loadMoreIfNeeded(currentItem item: Item) {
        guard let lastItem = items.last else { return }
        if item.id == lastItem.id && !metadata.last && !isLoadingMore {
            Task { await getItems(organizationId: selectedOrganizationID) }
        }
    }
    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }
    
    
    func getCoordinates(for organization: Organization, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let fullAddress = "\(organization.street) \(organization.streetNumber), \(organization.city), \(organization.country)"
        CLGeocoder().geocodeAddressString(fullAddress) { placemarks, error in
            if let location = placemarks?.first?.location {
                completion(location.coordinate)
            } else {
                print("coords failed: \(error?.localizedDescription ?? "?")")
                completion(nil)
            }
        }
    }
    
    func updateCoordinate(for organization: Organization) {
        let fullAddress = "\(organization.street) \(organization.streetNumber), \(organization.city), \(organization.country)"
        CLGeocoder().geocodeAddressString(fullAddress) { placemarks, error in
            if let coord = placemarks?.first?.location?.coordinate {
                self.selectedCoordinate = coord
                self.mapPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                ))
            } else {
                print("loc not found: \(error?.localizedDescription ?? "?")")
            }
        }
    }
}
