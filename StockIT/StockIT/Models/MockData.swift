
import Foundation

struct MockData {
    
    private static let isoFormatter = ISO8601DateFormatter()
    
    static let sampleOrganization: Organization = Organization(
        organizationId: "1",
        name: "FIIT STU",
        description: "Sklad FIIT STU",
        street: "Iľkovičova",
        streetNumber: "2",
        city: "Bratislava",
        postalCode: "81101",
        country: "Slovensko",
        createdBy: "1",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: "2",
        lastEditAt: "2025-03-28T12:00:00"
    )
    
    static let sampleOrganization2: Organization = Organization(
        organizationId: "2",
        name: "STUBA ADMIN",
        description: "Sklad Fakulty informatiky",
        street: "Vazovova",
        streetNumber: "5",
        city: "Bratislava",
        postalCode: "81243",
        country: "Slovensko",
        createdBy: "2",
        createdAt: "2025-02-10T09:15:00",
        lastEditBy: "3",
        lastEditAt: "2025-03-28T13:45:00"
    )
    
    static let sampleOrganization3: Organization = Organization(
        organizationId: "3",
        name: "TechHub",
        description: "Sklad technologického inkubátora",
        street: "Einsteinova",
        streetNumber: "19",
        city: "Bratislava",
        postalCode: "85101",
        country: "Slovensko",
        createdBy: "3",
        createdAt: "2025-03-01T08:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )


    static let organizations = [sampleOrganization, sampleOrganization2, sampleOrganization3]
    
    static let location1 = Location(
        locationId: "1",
        organizationId: "1",
        name: "Test Location 1",
        room: "A101",
        description: "Test description 1",
        itemCount: "23",
        createdBy: "1",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let location2 = Location(
        locationId: "2",
        organizationId: "1",
        name: "Test Location 2",
        room: "A102",
        description: "Test description 2",
        itemCount: "42",
        createdBy: "1",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let location3 = Location(
        locationId: "3",
        organizationId: "1",
        name: "Test Location 3",
        room: "A103",
        description: "Test description 3",
        itemCount: "31",
        createdBy: "1",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let location4 = Location(
        locationId: "4",
        organizationId: "1",
        name: "Test Location 4",
        room: "A104",
        description: "Test description 4",
        itemCount: "24",
        createdBy: "1",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let location5 = Location(
        locationId: "5",
        organizationId: "2",
        name: "Test Location 5",
        room: "B201",
        description: "Test description 5",
        itemCount: "19",
        createdBy: "2",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let location6 = Location(
        locationId: "6",
        organizationId: "2",
        name: "Test Location 6",
        room: "B202",
        description: "Test description 6",
        itemCount: "50",
        createdBy: "2",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let location7 = Location(
        locationId: "7",
        organizationId: "2",
        name: "Test Location 7",
        room: "B203",
        description: "Test description 7",
        itemCount: "30",
        createdBy: "2",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let location8 = Location(
        locationId: "8",
        organizationId: "2",
        name: "Test Location 8",
        room: "B204",
        description: "Test description 8",
        itemCount: "44",
        createdBy: "2",
        createdAt: "2025-01-01T12:00:00",
        lastEditBy: nil,
        lastEditAt: nil
    )

    static let sampleLocations = [
        location1, location2, location3, location4,
        location5, location6, location7, location8
    ]
    
    static let items: [Item] = [
    Item(
        itemId: "1",
        organizationId: "1",
        locationId: "1",
        name: "MacBook Pro",
        description: "Výkonný pracovný notebook",
        status: "STORED",
        archived: "true",
        categories: [
            ItemCategory(categoryId: "1", name: "Notebooky", createdBy: "1", createdAt: "2025-03-30T10:15:00", lastEditBy: "1", lastEditAt:"2025-03-31T18:00:00")
        ],
        attributes: [
            ItemAttribute(attributeId: "1", name: "Hmotnosť", description: "2.5kg", value: "2.5", createdBy: "1", createdAt: "2025-03-30T10:15:00", lastEditBy: "1", lastEditAt: "2025-03-31T18:00:00")
        ],
        attachments: [
            
        ],
        createdBy: "1",
        createdAt: "2025-03-30T10:15:00",
        lastEditBy: "1",
        lastEditAt: "2025-03-31T18:00:00"
    ),
    Item(
        itemId: "2",
        organizationId: "1",
        locationId: "2",
        name: "Office Chair",
        description: "Ergonomická stolička s opierkou",
        status: "IN_USE",
        archived: "false",
        categories: [
            ItemCategory(categoryId: "2", name: "Nábytok", createdBy: "2", createdAt: "2025-03-01T10:00:00", lastEditBy: "2", lastEditAt:"2025-03-01T12:00:00")
        ],
        attributes: [
            ItemAttribute(attributeId: "2", name: "Farba", description: "Čierna", value: "Black", createdBy: "2", createdAt: "2025-03-10T11:00:00", lastEditBy: "2", lastEditAt: "2025-03-12T12:00:00")
        ],
        attachments: [
            
        ],
        createdBy: "2",
        createdAt: "2025-03-10T10:15:00",
        lastEditBy: "2",
        lastEditAt: "2025-03-12T12:00:00"
    ),
    Item(
        itemId: "3",
        organizationId: "2",
        locationId: "3",
        name: "Epson Projector",
        description: "HD projektor vhodný na prezentácie",
        status: "STORED",
        archived: "false",
        categories: [
            ItemCategory(categoryId: "3", name: "Elektronika", createdBy: "1", createdAt: "2025-01-10T08:00:00", lastEditBy: "1", lastEditAt:"2025-01-15T18:00:00")
        ],
        attributes: [
            ItemAttribute(attributeId: "3", name: "Rozlíšenie", description: "Full HD", value: "1920x1080", createdBy: "1", createdAt: "2025-01-10T08:00:00", lastEditBy: "1", lastEditAt: "2025-01-15T18:00:00")
        ],
        attachments: [
           
        ],
        createdBy: "1",
        createdAt: "2025-01-10T08:00:00",
        lastEditBy: "1",
        lastEditAt: "2025-01-15T18:00:00"
    ),
    ]
    
    static let mainUserSuperAdmin = User(
        userId: "1",
        email: "superadmin@stockit.sk",
        accountActive: "true",
        firstName: "SUPERADMIN",
        lastName: "STOCKIT_APP",
        phoneNumber: "0",
        address: "Adresa SuperAdmina",
        birthDate: "2000-01-01",
        description: "SUPERADMIN pre celú aplikáciu",
        userRoles: [
            UserRole(
                roleName: "SUPERADMIN",
                roleDescription: "Má úplný prístup k celej aplikácii",
                scopeType: "GLOBAL",
                scopeId: nil,
                permissions: [
                    RolePermission(
                        name: "EVERYTHING",
                        scopeType: "GLOBAL",
                        description: "Plný prístup ku všetkému (len superadmin) (vytvorenie organizácie, adminov, ...)"
                    )
                ]
            )
        ],
        permissionsFlatList: [
            Permission(
                permissionName: "EVERYTHING",
                scopeType: "GLOBAL",
                scopeId: nil,
                permissionDescription: "Plný prístup ku všetkému (len superadmin) (vytvorenie organizácie, adminov, ...)"
            )
        ],
        createdBy: "1",
        createdAt: "2025-04-24T12:49:00.372106",
        lastEditBy: "1",
        lastEditAt: "2025-04-24T15:24:52.435545",
        lastLoginAt: "2025-04-24T19:25:59.256117846"
    )
    
    static let mockGroup = OrganizationGroup(
        groupId: "1",
        organizationId: "1",
        name: "Testovacia skupina",
        description: "Skupina pre testovacie účely.",
        assignedLocations: [
            GroupLocation(
                locationId: "101",
                organizationId: "1",
                name: "Laboratórium A",
                room: "B105",
                description: "Miestnosť s digitálnym vybavením",
                itemCount: "12",
                createdBy: "1",
                createdAt: "2025-01-01T12:00:00",
                lastEditBy: "2",
                lastEditAt: "2025-03-01T09:45:00"
            )
        ],
        tenant: GroupUser(
            userId: "1",
            email: "tenant@example.com",
            firstName: "Anna",
            lastName: "Tenantová",
            phoneNumber: "+421911123456",
            description: "Zodpovedná osoba skupiny"
        ),
        members: [
            GroupUser(
                userId: "u",
                email: "clen@example.com",
                firstName: "Ján",
                lastName: "Novák",
                phoneNumber: "+421900654321",
                description: "Bežný člen skupiny"
            )
        ],
        createdBy: "1",
        createdAt: "2025-04-24T18:36:53.144886",
        lastEditBy: "2",
        lastEditAt: "2025-05-24T18:36:53.144886"
    )
    
    static let mockSuggestions: [Suggestion] = [
        Suggestion(
            name: "macicka",
            description: "zlata mala",
            imageURL: "https://serpapi.com/searches/682136a773bf595d074b4098/images/aaaae051dc7f72ac0dec3bf3bab100d9384d477b05e018859289df86f507c1c0.jpeg",
            percentage: 89.14
        ),
        Suggestion(
            name: "cat°• - YouTube",
            description: "youtube video",
            imageURL: "https://yt3.googleusercontent.com/3AWFVdlxP7Da1i-E_I8sjUzWBvhnnBExlPZiMqMXOBT6efpf9PhElJ_QwqPOj_jyjJEaztr5=s160-c-k-c0x00ffffff-no-rj",
            percentage: 88.01
        ),
        Suggestion(
            name: "Funny Cats Compilation",
            description: "hahah",
            imageURL: "https://i.ytimg.com/vi/vH8kYVahdrU/maxresdefault.jpg",
            percentage: 69.59
        )
    ]
    
}
