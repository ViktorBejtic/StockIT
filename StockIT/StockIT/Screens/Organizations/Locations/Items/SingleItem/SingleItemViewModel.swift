import Foundation
import SwiftUI
import PhotosUI
import Kingfisher
import AlertToast

@MainActor
class SingleItemViewModel: ObservableObject {
    @AppStorage("useAI") var useAI: Bool = true
    @Published var organizations: [Organization] = []
    @Published var locations: [Location] = []
    
    var filteredLocations: [Location] {
        guard let orgId = selectedOrganizationId else { return [] }
        return locations.filter { String($0.organizationId) == String(orgId) }
    }
    
    @Published var selectedOrganizationId: Int? {
        didSet { selectedLocationId = nil }
    }
    @Published var selectedLocationId: Int?
    @Published var checkLocationsAndOrganizations: Bool = false
    
    @Published var suggestions: [Suggestion] = []
    @Published var showSuggestions: Bool = false
    @Published var isIdentifying: Bool = false
    
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var status: ItemStatus? = .stored
    
    @Published var selectedCategories: [ItemCategory] = []
    @Published var availableCategories: [ItemCategory] = []
    @Published var showCategories: Bool = false
    @Published var showCreateUpdateCategory: Bool = false
    
    @Published var selectedAttributes: [SelectedAttribute] = []
    @Published var availableAttributes: [Attribute] = []
    @Published var showAttributes: Bool = false
    @Published var showCreateUpdateAttribute: Bool = false
    
    @Published var currentPhotoIndex: Int = 0
    @Published var showUploadOptions = false
    @Published var uploadedPhotos: [ItemPhoto] = []
    @Published var filesToDelete: [String] = []
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var selectedPhotoItems: [PhotosPickerItem] = [] {
        didSet { loadPhotosFromPicker(autoIdentify: true) }
    }
    var isWizardMode: Bool = false
    
    @Published var itemDeleted: Bool = false
    @Published var createdItem: Item?
    @Published var isCreating: Bool = false
    var dismissAction: (() -> Void)?

    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var isSuccess: Bool = true
    
    @ObservedObject var itemsVM: ItemsViewModel
    
    private let itemService = ItemService()
    private let orgService = OrganizationService()
    
    init(selectedOrganizationId: Int? = nil, selectedLocationId: Int? = nil, itemsVM: ItemsViewModel? = nil) {
        self.selectedOrganizationId = selectedOrganizationId
        self.selectedLocationId = selectedLocationId
        self.itemsVM = itemsVM ?? ItemsViewModel(organization: MockData.sampleOrganization, location: MockData.location1)
    }
    
    func loadPhotosFromPicker(autoIdentify: Bool = true) {
        guard !selectedPhotoItems.isEmpty else { return }
        let items = selectedPhotoItems
        Task {
            let isFirstPhoto = self.uploadedPhotos.isEmpty
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    self.uploadedPhotos.append(ItemPhoto(photo: uiImage, position: .random))
                    self.currentPhotoIndex = self.uploadedPhotos.count - 1
                }
            }
            self.selectedPhotoItems = []

            if autoIdentify && isFirstPhoto && !self.uploadedPhotos.isEmpty && self.useAI {
                self.identifyItem(image: self.uploadedPhotos.first!.photo)
            }
        }
    }
    
    func loadExistingPhotos(from item: Item) {
        let imageAttachments = item.attachments.filter { $0.type == "IMAGE" }
        
        let token = SecureStorage().get("AccessToken") ?? ""
        let modifier = AnyModifier { request in
            var r = request
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return r
        }
        
        for attachment in imageAttachments {
            let fullURLString = NetworkClient.shared.baseURL.absoluteString + attachment.link
            let encodedString = fullURLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? fullURLString
            
            guard let url = URL(string: encodedString) else { continue }
            
            KingfisherManager.shared.retrieveImage(with: url, options: [.requestModifier(modifier)]) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let value):
                        if let position = ItemPhotoPosition(rawValue: attachment.position) {
                            if !self.uploadedPhotos.contains(where: { $0.fileId == attachment.fileId }) {
                                self.uploadedPhotos.append(ItemPhoto(photo: value.image, position: position, fileId: attachment.fileId))
                                self.currentPhotoIndex = 0
                            }
                        }
                    case .failure(let error):
                        print("image load failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    var canSubmit: Bool {
        let hasPhotos = !uploadedPhotos.isEmpty
        let hasOrgAndLoc = selectedOrganizationId != nil && selectedLocationId != nil
        let hasTextFields = !name.trimmingCharacters(in: .whitespaces).isEmpty &&
                            !description.trimmingCharacters(in: .whitespaces).isEmpty &&
                            status != nil
        let hasCategories = !selectedCategories.isEmpty
        let noEmptyAttribute = selectedAttributes.allSatisfy { $0.value != "" }

        return hasPhotos && hasOrgAndLoc && hasTextFields && hasCategories && noEmptyAttribute
    }
    
    func canProceed(to nextStep: Int) -> Bool {
        switch nextStep {
        case 0: return !uploadedPhotos.isEmpty
        case 1: return selectedOrganizationId != nil && selectedLocationId != nil
        case 2: return !name.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !description.trimmingCharacters(in: .whitespaces).isEmpty && status != nil
        case 3: return !selectedCategories.isEmpty
        default: return true
        }
    }
    
    func filterLocationsAndOrganizations(user: User) {
        let allowedLocations = locations.filter { location in
            user.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
            user.permissionsFlatList.contains(where: {
                $0.permissionName == "CREATE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == location.locationId
            }) ||
            user.permissionsFlatList.contains(where: {
                $0.permissionName == "CREATE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == location.organizationId
            })
        }
        
        self.locations = allowedLocations
        let allowedOrgIds = Set(allowedLocations.map { $0.organizationId })
        self.organizations = organizations.filter { allowedOrgIds.contains($0.organizationId) }
    }
    
    
    func fetchData(forceRefresh: Bool = false) {
        Task {
            await getOrganizations(forceRefresh: forceRefresh)
            getCategories(forceRefresh: forceRefresh)
            getAttributes(forceRefresh: forceRefresh)
        }
    }
    
    func getOrganizations(forceRefresh: Bool = false) async {
        do {
            self.organizations = try await orgService.getOrganizations(forceRefresh: forceRefresh)
            await getLocations(forceRefresh: forceRefresh)
        } catch {
            handleError(error)
        }
    }
    
    func getLocations(forceRefresh: Bool = false) async {
        var fetchedLocations: [Location] = []
        
        await withTaskGroup(of: [Location]?.self) { taskGroup in
            for organization in organizations {
                taskGroup.addTask {
                    return try? await self.orgService.getLocations(organizationId: organization.id, forceRefresh: forceRefresh)
                }
            }
            for await locs in taskGroup {
                if let locs = locs { fetchedLocations.append(contentsOf: locs) }
            }
        }
        
        self.locations = fetchedLocations
        self.checkLocationsAndOrganizations = true
        print("locs: \(self.locations.count)")
    }
    
    func getLocationName(locationId: String, completion: @escaping (String) -> Void) {
        Task {
            do { completion(try await orgService.getLocationDetails(locationId: locationId).name) }
            catch { completion("Unknown Location") }
        }
    }
    
    func getOrganizationName(organizationId: String, completion: @escaping (String) -> Void) {
        Task {
            do { completion(try await orgService.getOrganizationDetails(organizationId: organizationId).name) }
            catch { completion("Unknown Organization") }
        }
    }
    
    func createItem() {
        guard let locationId = selectedLocationId.map(String.init) else { return }

        let newItem = CreateItemRequest(
            locationId: locationId, itemName: name, description: description,
            status: status?.rawValue ?? "", itemCategories: selectedCategories.map { $0.categoryId },
            itemAttributes: selectedAttributes.map { AttributeValuePair(attributeId: $0.attribute.attributeId, value: $0.value) }
        )

        isCreating = true

        Task {
            do {
                let createdItem = try await itemService.createItem(item: newItem)
                await uploadPhotos(itemID: createdItem.itemId, create: false)

                let completeItem = try await itemService.getItemDetails(itemID: createdItem.itemId)

                if let index = self.itemsVM.items.firstIndex(where: { $0.id == completeItem.id }) {
                    self.itemsVM.items[index] = completeItem
                } else {
                    self.itemsVM.items.append(completeItem)
                }

                self.isCreating = false
                self.createdItem = completeItem
            } catch {
                self.isCreating = false
                let newPhotos = uploadedPhotos.filter { $0.fileId == nil }
                OfflineSyncManager.shared.enqueueItemTask(action: .create, request: newItem, uiPhotos: newPhotos)
                print("saved offline")
            }
        }
    }
        
    func updateItem(item: Binding<Item>, refreshFlag: Binding<Bool>) {
        Task {
            if !filesToDelete.isEmpty { await deletePhotos(itemID: item.wrappedValue.itemId) }
            
            guard let locationId = selectedLocationId.map(String.init) else { return }
            
            let updatedRequest = CreateItemRequest(
                locationId: locationId, itemName: name, description: description,
                status: status?.rawValue ?? "", itemCategories: selectedCategories.map { $0.categoryId },
                itemAttributes: selectedAttributes.map { AttributeValuePair(attributeId: $0.attribute.attributeId, value: $0.value) }
            )
            
            do {
                let updatedItem = try await itemService.updateItem(itemID: item.wrappedValue.id, item: updatedRequest)
                
                if uploadedPhotos.contains(where: { $0.fileId == nil }) {
                    await uploadPhotos(itemID: item.wrappedValue.itemId, create: false)
                }
                
                item.wrappedValue = updatedItem
                refreshFlag.wrappedValue = true
            } catch {
                let newPhotos = uploadedPhotos.filter { $0.fileId == nil }
                OfflineSyncManager.shared.enqueueItemTask(action: .update, itemId: item.wrappedValue.itemId, request: updatedRequest, uiPhotos: newPhotos)
                self.toastMessage = "offlineItemWillBeCreated"
                self.isSuccess = true
                self.showToast = true
                print("update saved offline")
            }
        }
    }
    
    func archiveItem(item: Binding<Item>, refreshFlag: Binding<Bool>) {
        Task {
            do {
                try await itemService.archiveItem(itemID: item.wrappedValue.id)
                item.wrappedValue.archived = "true"
                refreshFlag.wrappedValue = true
            } catch { handleError(error) }
        }
    }
    
    func unarchiveItem(item: Binding<Item>) {
        Task {
            do {
                try await itemService.unarchiveItem(itemID: item.wrappedValue.id)
                item.wrappedValue.archived = "false"
            } catch { handleError(error) }
        }
    }
    
    func deleteItem(item: Binding<Item>, refreshFlag: Binding<Bool>) {
        Task {
            do {
                try await itemService.deleteItem(itemID: item.wrappedValue.id)
                item.wrappedValue.archived = "deleted"
                refreshFlag.wrappedValue = true
                self.itemDeleted = true
            } catch { handleError(error) }
        }
    }
    
    func identifyItem(image: UIImage) {
        self.isIdentifying = true
        if !isWizardMode {
            self.toastMessage = "aiIdentifyingItem"
            self.isSuccess = true
            self.showToast = true
        }
        self.suggestions = []
        Task {
            do {
                async let categoriesTask = itemService.getCategories()
                let categories = (try? await categoriesTask) ?? []
                let response = try await itemService.identifyItem(image: image, availableCategories: categories)
                self.suggestions = response.suggestions
                self.isIdentifying = false
                self.showToast = false
                if !self.isWizardMode {
                    self.showSuggestions = true
                }
                fetchSuggestionImages()
            } catch {
                self.isIdentifying = false
                self.showToast = false
                handleError(error)
            }
        }
    }

    func fetchSuggestionImages() {
        for i in suggestions.indices {
            let name = suggestions[i].name
            Task {
                if let url = await GoogleSearchService.shared.fetchImage(for: name) {
                    self.suggestions[i].imageURL = url
                }
            }
        }
    }
    
    func uploadPhotos(itemID: String, create: Bool) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for photo in uploadedPhotos where photo.fileId == nil {
                taskGroup.addTask {
                    do {
                        try await self.itemService.uploadPhoto(photo: photo, itemId: itemID)
                        print("photo uploaded: \(photo.id)")
                    } catch {
                        print("photo upload failed: \(photo.id)")
                    }
                }
            }
        }
        if create {
            itemsVM.getItemDetails(itemID: itemID)
        }
    }
    
    func deletePhotos(itemID: String) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for fileID in filesToDelete {
                taskGroup.addTask {
                    do {
                        try await self.itemService.deletePhoto(fileID: fileID, itemID: itemID)
                        print("photo deleted: \(fileID)")
                    } catch {
                        print("photo delete failed: \(fileID)")
                    }
                }
            }
        }
    }
    
    func getCategories(forceRefresh: Bool = false) {
        Task { do { self.availableCategories = try await itemService.getCategories(forceRefresh: forceRefresh) } catch { handleError(error) } }
    }
    
    func createCategory(name: String) {
        Task {
            do {
                let newCat = try await itemService.createCategory(name: name)
                self.availableCategories.append(newCat)
                self.showCreateUpdateCategory = false
            } catch { handleError(error) }
        }
    }
    
    func updateCategory(name: String, categoryId: Int) {
        Task {
            do {
                let updated = try await itemService.updateCategory(name: name, categoryId: categoryId)
                if let index = self.availableCategories.firstIndex(where: { $0.id == updated.id }) {
                    self.availableCategories[index] = updated
                }
                if let index = self.selectedCategories.firstIndex(where: { $0.id == updated.id }) {
                    self.selectedCategories[index] = updated
                }
                self.showCreateUpdateCategory = false
            } catch { handleError(error) }
        }
    }
    
    func deleteCategory(categoryId: Int) {
        Task {
            do {
                try await itemService.deleteCategory(categoryId: categoryId)
                self.availableCategories.removeAll(where: { $0.id == categoryId })
                self.selectedCategories.removeAll(where: { $0.id == categoryId })
                self.showCreateUpdateCategory = false
            } catch { handleError(error) }
        }
    }
    
    func getAttributes(forceRefresh: Bool = false) {
        Task { do { self.availableAttributes = try await itemService.getAttributes(forceRefresh: forceRefresh) } catch { handleError(error) } }
    }
    
    func createAttribute(name: String, description: String) {
        Task {
            let req = CreateUpdateAttributeRequest(name: name, description: description)
            do {
                let newAttr = try await itemService.createAttribute(newAttribute: req)
                self.availableAttributes.append(newAttr)
                self.showCreateUpdateAttribute = false
            } catch { handleError(error) }
        }
    }
    
    func updateAttribute(name: String, description: String, attributeId: Int) {
        Task {
            let req = CreateUpdateAttributeRequest(name: name, description: description)
            do {
                let updated = try await itemService.updateAttribute(existingAttribute: req, attributeId: attributeId)
                if let index = self.availableAttributes.firstIndex(where: { $0.id == updated.id }) {
                    self.availableAttributes[index] = updated
                }
                self.showCreateUpdateAttribute = false
            } catch { handleError(error) }
        }
    }
    
    func deleteAttribute(attributeId: Int) {
        Task {
            do {
                try await itemService.deleteAttribute(attributeId: attributeId)
                self.availableAttributes.removeAll(where: { $0.id == attributeId })
                self.selectedAttributes.removeAll(where: { $0.id == attributeId })
                self.showCreateUpdateAttribute = false
            } catch { handleError(error) }
        }
    }
    
    private func handleError(_ error: Error) {
        let message = (error as? ErrorResponse)?.message ?? error.localizedDescription
        print("error: \(message)")
        UserSession.shared.alertMessage = message
        UserSession.shared.showAlert = true
    }
    
    @ViewBuilder
    func labeledField(_ label: String, text: Binding<String>, required: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(LocalizedStringKey(label)).foregroundStyle(.gray)
                if required { Text("*").foregroundStyle(.red) }
            }
            TextField("", text: text)
        }
    }
}
