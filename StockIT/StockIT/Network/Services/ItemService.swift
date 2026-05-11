import Foundation
import UIKit

class ItemService {
    private let client = NetworkClient.shared
    
    func getItems(organizations: [Int], locations: [Int], itemName: String, categories: [Int], attributes: [Int], statuses: [ItemStatus], archived: Bool, page: Int, size: Int, sort: String) async throws -> FilteredItemsResponse {
        var params: [String: Any] = [
            "showArchived": archived ? "true" : "false",
            "page": page,
            "size": size
        ]
        
        if !organizations.isEmpty { params["organizations"] = organizations }
        if !locations.isEmpty { params["locations"] = locations }
        if !itemName.trimmingCharacters(in: .whitespaces).isEmpty { params["itemName"] = itemName }
        if !categories.isEmpty { params["categories"] = categories }
        if !attributes.isEmpty { params["attributes"] = attributes }
        if !statuses.isEmpty { params["statuses"] = statuses.map { $0.rawValue } }
        if !sort.isEmpty { params["sort"] = sort }
        
        return try await client.request(path: "items/filter", parameters: params)
    }
    
    func getItemDetails(itemID: String) async throws -> Item {
        return try await client.request(path: "items/\(itemID)")
    }
    
    func createItem(item: CreateItemRequest) async throws -> Item {
        return try await client.request(path: "items", method: .post, body: item)
    }
    
    func updateItem(itemID: Int, item: CreateItemRequest) async throws -> Item {
        return try await client.request(path: "items/\(itemID)", method: .put, body: item)
    }
    
    func archiveItem(itemID: Int) async throws {
        try await client.requestVoid(path: "items/\(itemID)/archive", method: .put)
    }
    
    func unarchiveItem(itemID: Int) async throws {
        try await client.requestVoid(path: "items/\(itemID)/unarchive", method: .put)
    }
    
    func deleteItem(itemID: Int) async throws {
        try await client.requestVoid(path: "items/\(itemID)", method: .delete)
    }
    
    func uploadPhoto(photo: ItemPhoto, itemId: String) async throws {
        let params = ["item_id": itemId, "type": "IMAGE", "position": photo.position.rawValue]
        let _: EmptyResponse = try await client.uploadImage(path: "attachments/item/\(itemId)", image: photo.photo, paramName: "file", extraParams: params)
    }
    
    func deletePhoto(fileID: String, itemID: String) async throws {
        try await client.requestVoid(path: "attachments/item/\(itemID)/file/\(fileID)", method: .delete)
    }
    
    func identifyItem(image: UIImage, availableCategories: [ItemCategory] = []) async throws -> SuggestionResponse {
        let categoryNames = availableCategories.map { $0.name }
        let aiResults = await AIVisionService.shared.analyzePhoto(image, availableCategories: categoryNames)

        let suggestions = aiResults.map { aiItem in
            let cisloZPercent = aiItem.confidence.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            let percentageDouble = Double(cisloZPercent) ?? 0.0
            return Suggestion(
                name: aiItem.name,
                description: aiItem.description,
                imageURL: "",
                percentage: percentageDouble,
                suggestedCategoryNames: aiItem.categoryNames
            )
        }.sorted { $0.percentage > $1.percentage }

        return SuggestionResponse(suggestions: suggestions)
    }
    
    func getCategories(forceRefresh: Bool = false) async throws -> [ItemCategory] {
        if !forceRefresh {
            if let cached = try? APICacheManager.shared.categoriesStorage?.object(forKey: "all_categories") {
                return cached
            }
        }
        
        let fetched: [ItemCategory] = try await client.request(path: "categories")
        try? APICacheManager.shared.categoriesStorage?.setObject(fetched, forKey: "all_categories")
        return fetched
    }
    
    func createCategory(name: String) async throws -> ItemCategory {
        let cat: ItemCategory = try await client.request(path: "categories", method: .post, body: name)
        try? APICacheManager.shared.categoriesStorage?.removeObject(forKey: "all_categories")
        return cat
    }
    
    func updateCategory(name: String, categoryId: Int) async throws -> ItemCategory {
        let cat: ItemCategory = try await client.request(path: "categories/\(categoryId)", method: .put, body: name)
        try? APICacheManager.shared.categoriesStorage?.removeObject(forKey: "all_categories")
        return cat
    }
    
    func deleteCategory(categoryId: Int) async throws {
        try await client.requestVoid(path: "categories/\(categoryId)", method: .delete)
        try? APICacheManager.shared.categoriesStorage?.removeObject(forKey: "all_categories")
    }
    
    func getAttributes(forceRefresh: Bool = false) async throws -> [Attribute] {
        if !forceRefresh {
            if let cached = try? APICacheManager.shared.attributesStorage?.object(forKey: "all_attributes") {
                return cached
            }
        }
        
        let fetched: [Attribute] = try await client.request(path: "attributes")
        try? APICacheManager.shared.attributesStorage?.setObject(fetched, forKey: "all_attributes")
        return fetched
    }
    
    func createAttribute(newAttribute: CreateUpdateAttributeRequest) async throws -> Attribute {
        let attr: Attribute = try await client.request(path: "attributes", method: .post, body: newAttribute)
        try? APICacheManager.shared.attributesStorage?.removeObject(forKey: "all_attributes")
        return attr
    }
    
    func updateAttribute(existingAttribute: CreateUpdateAttributeRequest, attributeId: Int) async throws -> Attribute {
        let attr: Attribute = try await client.request(path: "attributes/\(attributeId)", method: .put, body: existingAttribute)
        try? APICacheManager.shared.attributesStorage?.removeObject(forKey: "all_attributes")
        return attr
    }
    
    func deleteAttribute(attributeId: Int) async throws {
        try await client.requestVoid(path: "attributes/\(attributeId)", method: .delete)
        try? APICacheManager.shared.attributesStorage?.removeObject(forKey: "all_attributes")
    }
}
