import Foundation
import SwiftUI
import CodeScanner

enum SearchFilterSheetType: Identifiable {
    case organizations, locations, categories, attributes, statuses
    
    var id: Int {
        switch self {
        case .organizations: return 0
        case .locations: return 1
        case .categories: return 2
        case .attributes: return 3
        case .statuses: return 4
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @AppStorage("itemsLayout") var itemsLayout: Int = 1
    @Published var showCreateItemView = false
    @Published var activeID: String?
    @Published var isLoadingMore = false
    
    @Published var items: [Item] = []
    @Published var metadata: Metadata = .default
    
    @Published var allCategories: [ItemCategory] = []
    @Published var allAttributes: [Attribute] = []
    
    @Published var activeFilterSheet: SearchFilterSheetType? = nil
    @Published var showAdvancedFilters = false
    
    @Published var allOrganizations: [Organization] = []
    @Published var allLocations: [Location] = []
    
    @Published var filters = ItemFilters()
    @Published var contextMenuItemIndex: Int? = nil
    @Published var selectedItem: Item? = nil
    @Published var shouldRefresh: Bool = false
    @Published var isLoading: Bool = false
    
    @Published var isShowingScanner = false
    
    var nextPage: Int = 0
    
    private let itemService = ItemService()
    private let orgService = OrganizationService()

    var showLocationName: Bool { filters.selectedLocationIDs.count != 1 }
    var showOrganizationName: Bool { filters.selectedOrganizationIDs.count != 1 }
    
    var areFiltersActive: Bool {
        !filters.selectedCategoryIDs.isEmpty ||
        !filters.selectedAttributeIDs.isEmpty ||
        !filters.selectedStatuses.isEmpty ||
        filters.showArchived ||
        filters.selectedSort != .createdAtDesc
    }
    
    var noItems: Bool {
        !filters.searchText.isEmpty ||
        !filters.selectedCategoryIDs.isEmpty ||
        !filters.selectedAttributeIDs.isEmpty ||
        !filters.selectedStatuses.isEmpty
    }

    
    func getData(forceRefresh: Bool = false) {
        Task {
            nextPage = 0
            await getItems()
            await fetchStaticData(forceRefresh: forceRefresh)
        }
    }
    
    func getItems() async {
        guard !isLoadingMore else { return }
        
        if nextPage == 0 { isLoading = true }
        isLoadingMore = true
        
        do {
            let response = try await itemService.getItems(
                organizations: filters.selectedOrganizationIDs,
                locations: filters.selectedLocationIDs,
                itemName: filters.searchText,
                categories: filters.selectedCategoryIDs,
                attributes: filters.selectedAttributeIDs,
                statuses: filters.selectedStatuses,
                archived: filters.showArchived,
                page: nextPage,
                size: metadata.size,
                sort: filters.selectedSort.rawValue
            )
            
            if response.metadata.first {
                self.items = response.data
            } else {
                self.items.append(contentsOf: response.data)
            }
            
            self.metadata = response.metadata
            self.nextPage = response.metadata.page + 1
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
        isLoadingMore = false
    }
    
    func refreshFilteredItems() {
            items.removeAll { $0.archived == "deleted" }
            
            if !filters.showArchived {
                items.removeAll { $0.archived == "true" }
            }
            
            if !filters.selectedOrganizationIDs.isEmpty {
                items.removeAll { !filters.selectedOrganizationIDs.contains(Int($0.organizationId) ?? -1) }
            }
            
            if !filters.selectedLocationIDs.isEmpty {
                items.removeAll { !filters.selectedLocationIDs.contains(Int($0.locationId) ?? -1) }
            }
            
            if !filters.selectedCategoryIDs.isEmpty {
                items.removeAll { item in
                    item.categories.allSatisfy { !filters.selectedCategoryIDs.contains(Int($0.categoryId) ?? -1) }
                }
            }
            
            if !filters.selectedAttributeIDs.isEmpty {
                items.removeAll { item in
                    item.attributes.allSatisfy { !filters.selectedAttributeIDs.contains(Int($0.attributeId) ?? -1) }
                }
            }
            
            if !filters.selectedStatuses.isEmpty {
                items.removeAll { !filters.selectedStatuses.map(\.rawValue).contains($0.status) }
            }
            
            if !filters.searchText.isEmpty {
                items.removeAll {
                    !$0.name.localizedCaseInsensitiveContains(filters.searchText) &&
                    !$0.description.localizedCaseInsensitiveContains(filters.searchText)
                }
            }
        }

    func fetchStaticData(forceRefresh: Bool = false) async {
        do {
            async let orgs = orgService.getOrganizations(forceRefresh: forceRefresh)
            async let cats = itemService.getCategories(forceRefresh: forceRefresh)
            async let attrs = itemService.getAttributes(forceRefresh: forceRefresh)
            
            self.allOrganizations = try await orgs
            self.allCategories = try await cats
            self.allAttributes = try await attrs
            
            await getAllLocations(forceRefresh: forceRefresh)
            
        } catch {
            handleError(error)
        }
    }

    private func getAllLocations(forceRefresh: Bool = false) async {
        var fetchedLocations: [Location] = []
        for org in allOrganizations {
            do {
                let locs = try await orgService.getLocations(organizationId: org.id, forceRefresh: forceRefresh)
                fetchedLocations.append(contentsOf: locs)
            } catch {
                print("locs failed: \(org.id)")
            }
        }
        self.allLocations = fetchedLocations
    }

    func loadMoreIfNeeded(currentItem item: Item) {
        guard let lastItem = items.last else { return }
        if item.id == lastItem.id && !metadata.last && !isLoadingMore {
            Task { await getItems() }
        }
    }
    
        
    func handleScan(result: Result<ScanResult, ScanError>) {
        self.isShowingScanner = false
        
        switch result {
        case .success(let scanResult):
            let rawScannedString = scanResult.string
            print("scanned: \(rawScannedString)")
            
            var extractedID: String = rawScannedString
            var extractedNameForSearch: String = rawScannedString

            if let jsonData = rawScannedString.data(using: .utf8) {
                do {
                    let payload = try JSONDecoder().decode(QRCodePayload.self, from: jsonData)
                    extractedID = String(payload.itemId)
                    if let name = payload.itemName {
                        extractedNameForSearch = name
                    }
                    print("found id: \(extractedID)")
                } catch {
                    print("not json")
                }
            }
            
            if let existingItem = self.items.first(where: { String($0.id) == extractedID }) {
                print("local hit")
                self.selectedItem = existingItem
                return
            }
            
            Task {
                isLoading = true
                
                do {
                    print("fetching: \(extractedID)")
                    let fetchedItem = try await itemService.getItemDetails(itemID: extractedID)
                    
                    self.items.insert(fetchedItem, at: 0)
                    self.selectedItem = fetchedItem
                    
                } catch {
                    print("fetch failed: \(error.localizedDescription)")
                    
                    self.filters.searchText = extractedNameForSearch
                    self.handleError(ErrorResponse.custom("Tento predmet sa v databáze nenašiel."))
                }
                
                isLoading = false
            }
            
        case .failure(let error):
            print("scan failed: \(error.localizedDescription)")
            self.handleError(ErrorResponse.custom("Nepodarilo sa naskenovať QR kód."))
        }
    }

    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }

    
    func toggleOrganization(id: Int, selectedOrganizations: inout [Int], selectedLocations: inout [Int]) {
            if selectedOrganizations.contains(id) {
                selectedOrganizations.removeAll(where: { $0 == id })
                let locs = allLocations.filter { Int($0.organizationId) ?? 0 == id }
                selectedLocations.removeAll(where: { locs.map(\.id).contains($0) })
            } else {
                selectedOrganizations.append(id)
                let locs = allLocations.filter { Int($0.organizationId) ?? 0 == id }
                for loc in locs where !selectedLocations.contains(loc.id) {
                    selectedLocations.append(loc.id)
                }
            }
        }
    
    func toggleOrganizationSelection(orgID: Int, selectedLocations: inout [Int], selectedOrganizations: inout [Int]) {
        let locations = allLocations.filter { Int($0.organizationId) ?? 0 == orgID }
        let allSelected = locations.allSatisfy { selectedLocations.contains($0.id) }
        
        if allSelected {
            selectedLocations.removeAll(where: { locations.map(\.id).contains($0) })
            selectedOrganizations.removeAll(where: { $0 == orgID })
        } else {
            for loc in locations where !selectedLocations.contains(loc.id) {
                selectedLocations.append(loc.id)
            }
            if !selectedOrganizations.contains(orgID) { selectedOrganizations.append(orgID) }
        }
    }

    func toggleLocationSelection(_ location: Location, selectedLocations: inout [Int], selectedOrganizations: inout [Int]) {
        if let index = selectedLocations.firstIndex(of: location.id) {
            selectedLocations.remove(at: index)
        } else {
            selectedLocations.append(location.id)
        }
        updateOrganizationSelection(orgID: Int(location.organizationId) ?? 0, selectedLocations: &selectedLocations, selectedOrganizations: &selectedOrganizations)
    }

    func updateOrganizationSelection(orgID: Int, selectedLocations: inout [Int], selectedOrganizations: inout [Int]) {
        let locations = allLocations.filter { Int($0.organizationId) ?? 0 == orgID}
        let selectedCount = locations.filter { selectedLocations.contains($0.id) }.count
        
        if selectedCount > 0 {
            if !selectedOrganizations.contains(orgID) { selectedOrganizations.append(orgID) }
        } else {
            selectedOrganizations.removeAll(where: { $0 == orgID })
        }
    }
    
    func allLocationsSelected(for orgID: Int, selectedLocations: [Int]) -> Bool {
            let locations = allLocations.filter { Int($0.organizationId) ?? 0 == orgID }
            return !locations.isEmpty && locations.allSatisfy { selectedLocations.contains($0.id) }
        }
}
