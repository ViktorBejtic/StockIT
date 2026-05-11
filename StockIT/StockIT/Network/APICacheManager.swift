import Foundation
import Cache

class APICacheManager {
    static let shared = APICacheManager()
    

    private let hourlyDiskConfig = DiskConfig(name: "StockIT_HourlyCache", expiry: .seconds(3600))
    private let hourlyMemoryConfig = MemoryConfig(expiry: .seconds(3600), countLimit: 50, totalCostLimit: 50)
    
    private let shortDiskConfig = DiskConfig(name: "StockIT_ShortCache", expiry: .seconds(900))
    private let shortMemoryConfig = MemoryConfig(expiry: .seconds(900), countLimit: 50, totalCostLimit: 50)


    lazy var categoriesStorage: Storage<String, [ItemCategory]>? = {
        return try? Storage(
            diskConfig: hourlyDiskConfig,
            memoryConfig: hourlyMemoryConfig,
            fileManager: FileManager.default,
            transformer: TransformerFactory.forCodable(ofType: [ItemCategory].self)
        )
    }()
    
    lazy var attributesStorage: Storage<String, [Attribute]>? = {
        return try? Storage(
            diskConfig: hourlyDiskConfig,
            memoryConfig: hourlyMemoryConfig,
            fileManager: FileManager.default,
            transformer: TransformerFactory.forCodable(ofType: [Attribute].self)
        )
    }()
    
    lazy var organizationsStorage: Storage<String, [Organization]>? = {
        return try? Storage(
            diskConfig: shortDiskConfig,
            memoryConfig: shortMemoryConfig,
            fileManager: FileManager.default,
            transformer: TransformerFactory.forCodable(ofType: [Organization].self)
        )
    }()
    
    lazy var locationsStorage: Storage<String, [Location]>? = {
        return try? Storage(
            diskConfig: shortDiskConfig,
            memoryConfig: shortMemoryConfig,
            fileManager: FileManager.default,
            transformer: TransformerFactory.forCodable(ofType: [Location].self)
        )
    }()
    
    lazy var groupsStorage: Storage<String, [OrganizationGroup]>? = {
        return try? Storage(
            diskConfig: shortDiskConfig,
            memoryConfig: shortMemoryConfig,
            fileManager: FileManager.default,
            transformer: TransformerFactory.forCodable(ofType: [OrganizationGroup].self)
        )
    }()
    
    lazy var usersStorage: Storage<String, [User]>? = {
        return try? Storage(
            diskConfig: shortDiskConfig,
            memoryConfig: shortMemoryConfig,
            fileManager: FileManager.default,
            transformer: TransformerFactory.forCodable(ofType: [User].self)
        )
    }()
    
    func clearAll() {
        try? organizationsStorage?.removeAll()
        try? categoriesStorage?.removeAll()
        try? attributesStorage?.removeAll()
        try? locationsStorage?.removeAll()
        try? groupsStorage?.removeAll()
        try? usersStorage?.removeAll()
        print("cache cleared")
    }
}
