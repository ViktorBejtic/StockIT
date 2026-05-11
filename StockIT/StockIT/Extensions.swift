
import Foundation
import SwiftUI

extension String {
    var localized: String {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        let code = lang == "system" ? Locale.current.language.languageCode?.identifier ?? "en" : lang
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }

    var toDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: self)
    }
    
    var relativeTime: String {
        guard let date = self.toDate else { return "N/A" }
        return date.relativeTime
    }
    
    var humanized: String {
        self.lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    var scopeOrder: Int {
        switch self.uppercased() {
        case "GLOBAL": return 0
        case "ORGANIZATION": return 1
        case "GROUP": return 2
        case "LOCATION": return 3
        default: return 999
        }
    }
}

extension Date {
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension UIImage {
    func isEqualToImage(_ image: UIImage) -> Bool {
        return self.pngData() == image.pngData()
    }
}

extension UserRole {
    var id: String {
        return "\(roleName)-\(scopeId ?? scopeType)"
    }
}

extension Role {
    var id: String {
        return "\(name)-\(scopeType)"
    }
}


extension Location {
    init(from groupLoc: GroupLocation) {
        self.locationId = groupLoc.locationId
        self.organizationId = groupLoc.organizationId
        self.name = groupLoc.name
        self.room = groupLoc.room
        self.description = groupLoc.description
        self.itemCount = groupLoc.itemCount ?? "0" 
        self.createdBy = groupLoc.createdBy
        self.createdAt = groupLoc.createdAt
        self.lastEditBy = groupLoc.lastEditBy
        self.lastEditAt = groupLoc.lastEditAt
    }
}
