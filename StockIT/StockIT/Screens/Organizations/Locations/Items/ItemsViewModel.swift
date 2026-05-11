import Foundation
import SwiftUI

enum FilterSheetType: Identifiable {
    case categories
    case attributes
    case statuses
    
    var id: Int {
        switch self {
        case .categories: return 0
        case .attributes: return 1
        case .statuses: return 2
        }
    }
}

@MainActor
class ItemsViewModel: ObservableObject {
    @AppStorage("itemsLayout") var itemsLayout: Int = 1
    @AppStorage("useWizard") var useWizard: Bool = true
    @Published var showCreateItemView = false
    @Published var activeID: String?
    @Published var isLoadingMore = false

    @Published var items: [Item] = []
    @Published var metadata: Metadata = .default
    
    @Published var allCategories: [ItemCategory] = []
    @Published var allAttributes: [Attribute] = []
    
    @Published var activeFilterSheet: FilterSheetType? = nil
    @Published var showAdvancedFilters = false
    
    @Published var organization: Organization
    @Published var location: Location

    @Published var filters = ItemFilters()
    
    var nextPage: Int = Metadata.default.page
    
    @Published var contextMenuItemIndex: Int? = nil
    @Published var selectedItem: Item? = nil
    
    @Published var shouldRefresh: Bool = false
    @Published var isLoading: Bool = false
    
    private let itemService = ItemService()
    private let orgService = OrganizationService()
    
    init(organization: Organization, location: Location) {
        self.organization = organization
        self.location = location
        
        if organization.id != -1 {
            filters.selectedOrganizationIDs = [organization.id]
        }
        
        if location.id != -1 {
            filters.selectedLocationIDs = [location.id]
        }
    }
    
    
    func refreshFilteredItems() {
        items.removeAll { $0.archived == "deleted" }
        
        if !filters.showArchived {
            items.removeAll { $0.archived == "true" }
        }
        
        if location.id == -1 {
            items.removeAll { $0.organizationId != organization.organizationId }
        } else {
            items.removeAll { $0.locationId != location.locationId }
        }
        
        if !filters.selectedCategoryIDs.isEmpty {
            items.removeAll { item in
                item.categories.allSatisfy {
                    !filters.selectedCategoryIDs.contains(Int($0.categoryId) ?? -1)
                }
            }
        }
        
        if !filters.selectedAttributeIDs.isEmpty {
            items.removeAll { item in
                item.attributes.allSatisfy {
                    !filters.selectedAttributeIDs.contains(Int($0.attributeId) ?? -1)
                }
            }
        }
        
        if !filters.selectedStatuses.isEmpty {
            items.removeAll {
                !filters.selectedStatuses.map(\.rawValue).contains($0.status)
            }
        }
        
        if !filters.searchText.isEmpty {
            items.removeAll {
                !$0.name.localizedCaseInsensitiveContains(filters.searchText) &&
                !$0.description.localizedCaseInsensitiveContains(filters.searchText)
            }
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
    
    
    func getItems() {
        guard !isLoadingMore else { return }
        
        Task {
            if nextPage == Metadata.default.page {
                self.isLoading = true
            }
            isLoadingMore = true
            
            do {
                let responseItems = try await itemService.getItems(
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
                
                if responseItems.metadata.first {
                    self.items = responseItems.data
                } else {
                    self.items.append(contentsOf: responseItems.data)
                }
                
                self.metadata = responseItems.metadata
                self.nextPage = responseItems.metadata.page + 1
            } catch {
                handleError(error)
            }
            
            self.isLoading = false
            self.isLoadingMore = false
        }
    }
    
    func getItemDetails(itemID: String) {
        Task {
            do {
                let responseItem = try await itemService.getItemDetails(itemID: itemID)
                if let index = self.items.firstIndex(where: { $0.id == responseItem.id }) {
                    self.items[index] = responseItem
                } else {
                    self.items.append(responseItem)
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func loadMoreIfNeeded(currentItem item: Item) {
        guard let lastItem = items.last else { return }
        if item.id == lastItem.id && !metadata.last && !isLoadingMore {
            getItems()
        }
    }
    
    func getCategories() {
        Task {
            do {
                self.allCategories = try await itemService.getCategories()
            } catch {
                handleError(error)
            }
        }
    }
    
    func getAttributes() {
        Task {
            do {
                self.allAttributes = try await itemService.getAttributes()
            } catch {
                handleError(error)
            }
        }
    }
    
    
    func getLocationName(locationId: String, completion: @escaping (String) -> Void) {
        Task {
            do {
                let location = try await orgService.getLocationDetails(locationId: locationId)
                completion(location.name)
            } catch {
                print(error.localizedDescription)
                completion("Unknown Location")
            }
        }
    }
    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }
    
    @ViewBuilder
    func filterChip(title: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(LocalizedStringKey(title + ":"))
                Text("\(count)").fontWeight(.bold)
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.fiitPrimary.opacity(0.1))
            .foregroundStyle(.fiitPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
