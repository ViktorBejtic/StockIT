
import Foundation
import SwiftUI

struct Item: Identifiable, Codable {
    var id: Int {
        return Int(itemId) ?? -1
    }
    
    let itemId: String
    let organizationId: String
    let locationId: String
    let name: String
    let description: String
    let status: String
    var archived: String
    let categories: [ItemCategory]
    let attributes: [ItemAttribute]
    let attachments: [ItemAttachment]
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case organizationId = "organization_id"
        case locationId = "location_id"
        case name = "item_name"
        case description
        case status
        case archived
        case categories
        case attributes
        case attachments
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}

struct ItemCategory: Identifiable, Codable {
    var id: Int {
        return Int(categoryId) ?? -1
    }
    
    let categoryId: String
    let name: String
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "id"
        case name
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}

struct ItemAttribute: Identifiable, Codable {
    var id: Int {
        return Int(attributeId) ?? -1
    }
    
    let attributeId: String
    let name: String
    let description: String
    let value: String
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    
    enum CodingKeys: String, CodingKey {
        case attributeId = "id"
        case name
        case description
        case value
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}

struct ItemAttachment: Codable, Identifiable {
    var id: Int {
        return Int(fileId) ?? -1
    }
    let link: String
    let type: String
    let position: String
    let itemId: String
    let fileId: String
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    
    enum CodingKeys: String, CodingKey {
        case link
        case type
        case position
        case itemId = "item_id"
        case fileId = "file_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}

struct Attribute: Codable, Identifiable {
    var id: Int {
        return Int(attributeId) ?? -1
    }
    
    let attributeId: String
    let name: String
    let description: String
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?
    
    enum CodingKeys: String, CodingKey {
        case attributeId = "id"
        case name
        case description
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}

enum ItemPhotoPosition: String, CaseIterable, Identifiable {
    case none = "---"
    case front = "FRONT"
    case back = "BACK"
    case left = "LEFT"
    case right = "RIGHT"
    case top = "TOP"
    case bottom = "BOTTOM"
    case topLeft = "TOP_LEFT"
    case topRight = "TOP_RIGHT"
    case bottomLeft = "BOTTOM_LEFT"
    case bottomRight = "BOTTOM_RIGHT"
    case angled = "ANGLED"
    case isometric = "ISOMETRIC"

    var id: String { rawValue }

    static var random: ItemPhotoPosition {
        let positions = Self.allCases.filter { $0 != .none }
        return positions.randomElement()!
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .none: return "---"
        case .front: return "fromFront"
        case .back: return "fromBack"
        case .left: return "fromLeft"
        case .right: return "fromRight"
        case .top: return "fromTop"
        case .bottom: return "fromBottom"
        case .topLeft: return "fromTopLeft"
        case .topRight: return "fromTopRight"
        case .bottomLeft: return "fromBottomLeft"
        case .bottomRight: return "fromBottomRight"
        case .angled: return "angledLabel"
        case .isometric: return "isometricLabel"
        }
    }
}

enum ItemStatus: String, CaseIterable, Identifiable {
    case stored = "STORED"
    case lost = "LOST"
    case disposed = "DISPOSED"
    case reserved = "RESERVED"
    case disposalPending = "DISPOSAL_PENDING"
    case toBeDisposed = "TO_BE_DISPOSED"
    case underReview = "UNDER_REVIEW"
    case borrowed = "BORROWED"
    case inUse = "IN_USE"
    case damaged = "DAMAGED"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .stored: return "statusStored"
        case .lost: return "statusLost"
        case .disposed: return "statusDisposed"
        case .reserved: return "statusReserved"
        case .disposalPending: return "statusDisposalPending"
        case .toBeDisposed: return "statusToBeDisposed"
        case .underReview: return "statusUnderReview"
        case .borrowed: return "statusBorrowed"
        case .inUse: return "statusInUse"
        case .damaged: return "statusDamaged"
        }
    }
}


enum ItemSort: String, CaseIterable, Identifiable {
    case createdAtDesc = "created_at:desc"
    case createdAtAsc = "created_at:asc"
    case lastEditAtDesc = "last_edit_at:desc"
    case lastEditAtAsc = "last_edit_at:asc"
    case itemNameAsc = "item_name:asc"
    case itemNameDesc = "item_name:desc"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .createdAtDesc: return "sortNewestFirst"
        case .createdAtAsc: return "sortOldestFirst"
        case .lastEditAtDesc: return "sortLastEditNewOld"
        case .lastEditAtAsc: return "sortLastEditOldNew"
        case .itemNameAsc: return "sortNameAZ"
        case .itemNameDesc: return "sortNameZA"
        }
    }

    var iconName: String {
        switch self {
        case .createdAtAsc, .createdAtDesc:
            return "clock"
        case .lastEditAtAsc, .lastEditAtDesc:
            return "clock.arrow.circlepath"
        case .itemNameAsc, .itemNameDesc:
            return "textformat"
        }
    }
}

struct ItemFilters: Equatable {
    var selectedOrganizationIDs: [Int] = []
    var selectedLocationIDs: [Int] = []
    var searchText: String = ""
    var selectedCategoryIDs: [Int] = []
    var selectedAttributeIDs: [Int] = []
    var selectedStatuses: [ItemStatus] = []
    var showArchived: Bool = false
    var selectedSort: ItemSort = .createdAtDesc
}

struct ItemPhoto: Identifiable {
    let id = UUID()
    var photo: UIImage
    var position: ItemPhotoPosition
    var fileId: String?
}

struct SelectedAttribute: Identifiable {
    let attribute: Attribute
    var value: String
    
    var id: Int {
        attribute.id
    }
}

struct CreateUpdateAttributeRequest: Codable {
    let name: String
    let description: String
}

struct FilteredItemsResponse: Decodable {
    let data: [Item]
    let metadata: Metadata
}

struct CreateItemRequest: Codable {
    let locationId: String
    let itemName: String
    let description: String
    let status: String
    let itemCategories: [String]
    let itemAttributes: [AttributeValuePair]
    
    enum CodingKeys: String, CodingKey {
        case locationId = "location_id"
        case itemName = "item_name"
        case description
        case status
        case itemCategories = "item_categories"
        case itemAttributes = "item_attributes"
    }
}

struct AttributeValuePair: Codable {
    let attributeId: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case attributeId = "attribute_id"
        case value
    }
}

struct Metadata: Decodable {
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let first: Bool
    let last: Bool
    let hasNext: Bool
    let hasPrevious: Bool
    let sort: [String]
    
    enum CodingKeys: String, CodingKey {
        case page, size, sort, first, last
        case totalElements = "total_elements"
        case totalPages = "total_pages"
        case hasNext = "has_next"
        case hasPrevious = "has_previous"
    }
    
    static let `default` = Metadata(
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
        first: true,
        last: false,
        hasNext: false,
        hasPrevious: false,
        sort: []
    )
}

struct Suggestion: Codable, Identifiable {
    let id: UUID = UUID()
    let name: String
    let description: String
    var imageURL: String
    let percentage: Double
    var suggestedCategoryNames: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case imageURL = "image_url"
        case percentage
        case suggestedCategoryNames = "suggested_categories"
    }

    init(name: String, description: String, imageURL: String, percentage: Double, suggestedCategoryNames: [String] = []) {
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.percentage = percentage
        self.suggestedCategoryNames = suggestedCategoryNames
    }
}

struct SuggestionResponse: Codable {
    let suggestions: [Suggestion]
}

struct QRCodePayload: Decodable {
    let itemId: Int
    let itemName: String?
    let itemDescription: String?
    let itemLocation: Int?
}
