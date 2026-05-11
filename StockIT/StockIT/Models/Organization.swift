import Foundation

struct Organization: Codable, Identifiable {
    var id: Int { Int(organizationId) ?? 0 }

    let organizationId: String
    let name: String
    let description: String
    let street: String
    let streetNumber: String
    let city: String
    let postalCode: String
    let country: String
    let createdBy: String?
    let createdAt: String?
    let lastEditBy: String?
    let lastEditAt: String?

    enum CodingKeys: String, CodingKey {
        case organizationId = "organization_id"
        case name = "organization_name"
        case description
        case street
        case streetNumber = "street_number"
        case city
        case postalCode = "postal_code"
        case country
        case createdBy = "created_by"
        case createdAt = "created_at"
        case lastEditBy = "last_edit_by"
        case lastEditAt = "last_edit_at"
    }
}


struct CreateUpdateOrganizationRequest: Codable {
    let name: String
    let description: String
    let street: String
    let streetNumber: String
    let city: String
    let postalCode: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case name = "organization_name"
        case description
        case street
        case streetNumber = "street_number"
        case city
        case postalCode = "postal_code"
        case country
    }
}

